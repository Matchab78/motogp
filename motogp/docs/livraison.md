# Transmettre et pousser le projet

Le dossier du projet est autonome : copier tout `motogp/` dans votre vrai dépôt de groupe, ou extraire l'archive livrée. Aucun fichier situé dans le dossier F1 parent n'est nécessaire.

Dans le dépôt Git du groupe, vérifier les fichiers avant le commit :

```bash
git status --short
git add motogp/
git diff --cached --stat
git diff --cached
git commit -m "Ajoute le pipeline dbt MotoGP testé et documenté"
git push
```

Ces commandes supposent que le projet a été copié dans un sous-dossier `motogp/`. Si son contenu est à la racine du dépôt, adapter `git add` en sélectionnant uniquement les fichiers du projet. Ne pas lancer `git init` dans le dossier de travail temporaire par erreur. Vérifier `git remote -v` pour confirmer le dépôt destinataire.

Le lanceur `.connection.json` est créé localement seulement ; chaque membre configure sa propre connexion. Les mots de passe ne doivent jamais être ajoutés à Git, même dans une capture. Les résultats dbt sous `target/` ne sont pas versionnés par défaut.

Le camarade récupère avec `git pull`, ouvre le dossier `motogp/`, puis exécute :

```bash
python run.py setup
python run.py configure
python run.py all
python run.py docs
```

S'il possède déjà les six tables, il n'a pas besoin d'importer les CSV. Pour une base vierge, utiliser le chemin d'import facultatif décrit dans le README. Il doit disposer de Python 3.10–3.13 et de l'accès PostgreSQL : aucun dépôt ne peut inclure ses droits d'accès ou deviner son mot de passe.
