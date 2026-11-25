# Rapport de performance – Optimisation de la requête `lap_times` (base `motogp`)

**Environnement :** PostgreSQL dans un conteneur Docker (`postgres-bench`), poste Fedora
**Méthode :** `EXPLAIN (ANALYZE, BUFFERS)` via `benchmarks.sql`, avant et après l'exécution de `index.sql`
**Requête testée :** agrégation par tour (`GROUP BY lap`) des temps d'un pilote sur une course
(`race_id = 1098 AND driver_id = 830`), soit 627 lignes lues et 57 groupes en sortie.

---

## 1. Synthèse

| Indicateur | Avant | Après (1ʳᵉ exécution) | Après (2ᵉ exécution, cache chaud) |
|---|---|---|---|
| **Temps d'exécution** | **36,263 ms** | **0,239 ms** | **0,211 ms** |
| Temps de planification | 0,282 ms | 0,377 ms | 0,317 ms |
| Temps total (planif. + exéc.) | 36,545 ms | 0,616 ms | 0,528 ms |
| Coût estimé (planificateur) | 2 476,29 | 10,27 | 17,01 |
| Blocs lus sur disque (`read`) | 149 | 7 | 0 |
| Blocs lus en cache (`hit`) | 3 | 171 | 178 |
| Stratégie d'accès | Bitmap AND sur 2 index + Heap Scan + Sort | Index Only Scan | Index Only Scan |
| Accès à la table (`Heap Fetches`) | 15 blocs de table | 0 | 0 |
| Nœuds dans le plan | 5 | 2 | 2 |

**Gain sur le temps d'exécution : environ ×152 (cache froid) à ×172 (cache chaud), soit une baisse de 99,3 % à 99,4 %.**
Sur le temps total, planification comprise, le gain est d'environ ×59 à ×69.

---

## 2. Analyse du plan initial (avant optimisation)

```
GroupAggregate                         actual 36.129..36.216 ms  rows=57
 └─ Sort (quicksort, 49 kB)            actual 36.119..36.140 ms  rows=627
     └─ Bitmap Heap Scan on lap_times  actual 33.455..36.035 ms  rows=627  (15 heap blocks)
         └─ BitmapAnd                  actual 33.149..33.150 ms
             ├─ Bitmap Index Scan lap_times_race_id_idx    4.800 ms   rows=11 605   buffers=12
             └─ Bitmap Index Scan lap_times_driver_id_idx 28.315 ms   rows=151 756  buffers=122
```

### Où part le temps

| Étape | Temps approx. | Part du total |
|---|---|---|
| Scan de l'index `driver_id` | 28,3 ms | ~78 % |
| Scan de l'index `race_id` | 4,8 ms | ~13 % |
| Lecture de la table (heap) + recheck | ~2,9 ms | ~8 % |
| Tri + agrégation | ~0,2 ms | < 1 % |

### Problèmes identifiés

1. **Deux index mono-colonne trop peu sélectifs.** PostgreSQL doit construire deux bitmaps et les intersecter (`BitmapAnd`) :
   - l'index `driver_id` renvoie **151 756** entrées pour n'en garder que **627**. **99,6 % du travail est inutile** ;
   - l'index `race_id` renvoie **11 605** entrées, dont 94,6 % sont écartées.
2. **Accès obligatoire à la table.** Les colonnes nécessaires à l'agrégat ne sont pas dans les index, il faut donc lire 15 blocs de la table et revérifier la condition (`Recheck Cond`).
3. **Tri supplémentaire.** Les lignes sortent dans l'ordre physique, il faut donc les trier par `lap` avant le `GroupAggregate`.
4. **I/O disque.** 149 blocs sur 152 sont lus depuis le disque (cache quasi vide).
5. **Estimation imprécise.** Le planificateur prévoit 176 lignes alors qu'il y en a 627 (sous-estimation d'environ ×3,6). Cela vient de la corrélation entre `race_id` et `driver_id`, que PostgreSQL traite comme indépendants.

---

## 3. Optimisation appliquée

Le script `index.sql` crée un **index composite couvrant** `idx_lap_times_race_driver_cover`, puis lance un `ANALYZE` pour mettre à jour les statistiques.

D'après le plan obtenu, l'index a cette forme (à confirmer avec le contenu de `index.sql`) :

```sql
CREATE INDEX idx_lap_times_race_driver_cover
    ON lap_times (race_id, driver_id, lap)
    INCLUDE (<colonne(s) agrégée(s)>);
ANALYZE lap_times;
```

- **`race_id, driver_id` en tête :** les deux filtres d'égalité sont résolus par une seule descente dans l'arbre B-tree.
- **`lap` ensuite :** les entrées sortent déjà triées par tour, donc **le nœud `Sort` disparaît**.
- **`INCLUDE` :** toutes les colonnes utiles sont dans l'index, ce qui permet un **Index Only Scan** sans lecture de la table.

---

## 4. Analyse du plan optimisé

```
GroupAggregate                                       actual 0.049..0.204 ms  rows=57
 └─ Index Only Scan using idx_lap_times_race_driver_cover
        Index Cond: (race_id = 1098) AND (driver_id = 830)
        Heap Fetches: 0                              actual 0.038..0.133 ms  rows=627
```

- **Un seul accès ciblé :** l'index renvoie directement les 627 lignes utiles, sans lignes parasites à filtrer.
- **`Heap Fetches: 0` :** la table n'est jamais lue. La visibility map est à jour (le `ANALYZE` ou un `VACUUM` récent a joué).
- **Plus de tri :** l'ordre de l'index suffit au `GroupAggregate`.
- **Presque tout en cache :** 7 blocs lus sur disque au 1ᵉʳ passage, puis 0 au 2ᵉ (100 % de `hit`).

### Comparaison des deux exécutions après optimisation

L'écart entre 0,239 ms et 0,211 ms (−12 %) vient du cache : les 7 blocs lus sur disque la première fois sont en mémoire la seconde.
L'estimation du planificateur a aussi bougé (174 puis 271 lignes estimées), probablement parce que les statistiques ont été rafraîchies entre-temps (nouvel `ANALYZE` ou autovacuum). Le plan choisi reste le même.

---

## 5. Points de vigilance

1. **La planification pèse maintenant plus que l'exécution.** 0,317 à 0,377 ms de planification contre 0,211 à 0,239 ms d'exécution. Si la requête est appelée très souvent, une **requête préparée** (`PREPARE` / paramètres liés côté application) permet d'économiser ce coût.
2. **Nombre de buffers légèrement plus élevé qu'avant.** 178 buffers lus contre 152, alors que seules 627 entrées sont utiles. Comme ils viennent du cache, l'impact est nul ici, mais c'est un volume étonnant pour un Index Only Scan aussi ciblé. À vérifier avec l'extension `pgstattuple` (`SELECT * FROM pgstatindex('idx_lap_times_race_driver_cover');`) pour détecter une éventuelle fragmentation ou une colonne `INCLUDE` trop large.
3. **L'estimation reste imprécise** (174 à 271 lignes estimées pour 627 réelles). Sans conséquence ici, mais ça peut fausser des plans plus complexes (jointures). Des statistiques étendues peuvent corriger cela :
   ```sql
   CREATE STATISTICS st_lap_times_race_driver (dependencies, ndistinct)
       ON race_id, driver_id FROM lap_times;
   ANALYZE lap_times;
   ```
4. **Coût en écriture et en stockage.** Chaque nouvel index ralentit les `INSERT` / `UPDATE` et occupe de l'espace disque. L'index `lap_times_race_id_idx` devient probablement **redondant**, puisque le nouvel index commence par `race_id`. Avant de le supprimer, il faut vérifier son usage :
   ```sql
   SELECT indexrelname, idx_scan
   FROM pg_stat_user_indexes
   WHERE relname = 'lap_times';
   ```
   `lap_times_driver_id_idx` reste utile pour les requêtes qui filtrent uniquement sur le pilote.
5. **Le visibility map doit rester à jour.** Le gain de l'Index Only Scan dépend de `Heap Fetches: 0`. Après des chargements massifs, il faut lancer un `VACUUM` (ou laisser l'autovacuum passer), sinon PostgreSQL revient lire la table.

---

## 6. Limites de la mesure

- **Une seule exécution par scénario.** Pour un résultat robuste, il faudrait lancer chaque requête plusieurs fois (10 à 30) et garder la médiane, en distinguant cache froid et cache chaud.
- **Conditions de cache différentes.** Le plan initial est mesuré cache quasi vide (149 lectures disque), le plan optimisé cache en partie chaud. Une partie du gain (faible face au ×150) vient donc du cache. Pour comparer à conditions égales, on peut redémarrer le conteneur avant chaque mesure ou relancer la requête initiale cache chaud.
- **Un seul couple `(race_id, driver_id)` testé.** Il faudrait valider sur d'autres pilotes et d'autres courses, notamment les cas extrêmes (pilote avec beaucoup de tours, course longue).

---

## 7. Conclusion

L'index composite couvrant `idx_lap_times_race_driver_cover` remplace un plan en 5 étapes (2 scans d'index, intersection de bitmaps, lecture de la table, tri) par un **Index Only Scan direct, sans tri et sans accès à la table**.
Le temps d'exécution passe de **36,3 ms à environ 0,2 ms (×150 à ×170)** et les lectures disque de **149 blocs à 0**.

**Prochaines étapes recommandées :**
1. Vérifier l'usage de `lap_times_race_id_idx` et le supprimer s'il est redondant.
2. Ajouter des statistiques étendues sur `(race_id, driver_id)`.
3. Refaire le benchmark sur plusieurs exécutions et plusieurs couples pilote/course pour consolider les chiffres.
