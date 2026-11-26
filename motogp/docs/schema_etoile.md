# Étoile des victoires enregistrées

![Schéma en étoile MotoGP](schema_etoile.png)

```mermaid
erDiagram
    dim_riders ||--o{ fct_wins : rider_key
    dim_constructors ||--o{ fct_wins : constructor_key
    dim_circuits ||--o{ fct_wins : circuit_key
    dim_seasons ||--o{ fct_wins : season_key
    dim_classes ||--o{ fct_wins : class_key
    fct_wins {
        text win_id PK
        text rider_key FK
        text constructor_key FK
        text circuit_key FK
        integer season_key FK
        text class_key FK
        integer win_count
    }
    dim_riders {
        text rider_key PK
        text rider_name
        text rider_country
    }
    dim_constructors {
        text constructor_key PK
        text constructor_name
        text constructor_label
    }
    dim_circuits {
        text circuit_key PK
        text circuit_name
        text circuit_country
        boolean circuit_matched
    }
    dim_seasons {
        integer season_key PK
        integer season
        integer decade
    }
    dim_classes {
        text class_key PK
        text class_name
    }
```

Grain : une ligne de victoire enregistrée. Chaque fait se rattache à exactement un membre de chacune des cinq dimensions. `win_count = 1` est la mesure additive. Un constructeur absent dispose d'un membre « Constructeur inconnu ».

PK et FK représentent ici les clés logiques contrôlées par dbt. Des contraintes physiques ne sont pas créées. Les dimensions sont de type 1 et reconstruites à chaque build ; le snapshot SCD2 du référentiel circuits est séparé de l'étoile.
