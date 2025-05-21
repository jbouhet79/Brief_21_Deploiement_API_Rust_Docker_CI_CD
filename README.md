# Brief 21

## Démarrer le projet en local sans Docker

- Installer Rust et Rustup <https://www.rust-lang.org/tools/install.>
- Créer et se connecter à une base de données postgresQL en local
- Compiler le projet avec Cargo: 
```
cargo build
```
- Exécuter le programme : 
```
cargo run
```


## Démarrer le projet en local avec Docker

- Réaliser le fichier ___Dockerfile___ (voir ci-dessous)

- __Construire l'image__ Docker à partir du ___Dockerfile___ situé dans le repertoire courant (.) et lui donner un tag (registry.nocturlab.fr/jbouhet/brief21-jb-v2):
```
docker build -t registry.nocturlab.fr/jbouhet/brief21-jb-v2 .
```

- __Envoyer l'image Docker__ vers le serveur : "registry.nocturlab.fr":
```
docker push registry.nocturlab.fr/jbouhet/brief21-jb-v2
```

- __Se connecter au serveur__: 
```
ssh owner@ssh.shiipou.fr
```
, puis mot de passe

- __Lancer le conteneur__ (en arrière- plan avec "-d") à partir de l'image : registry.nocturlab.fr/jbouhet/brief21-jb-v2
```
docker run -d registry.nocturlab.fr/jbouhet/brief21-jb-v2
```

- __Lancer les services__ définis dans le fichier ___compose.yml___ (en arrière- plan avec "-d"):
```
docker compose up -d
```

remarque : possibilité d'ajouter l'affichage des 100 dernères lignes de log de traefik
```
docker compose up -d && docker compose -p traefik logs -f -n100
```

- Vérifier que cela fonctionne dans le navigateur à l'adresse définie dans le compose.yml: <http://api-jb.nocturlab.fr>



## Fichier Dockerfile

````
FROM rust:1.87

WORKDIR /myapp
COPY . /myapp

RUN rustup default nightly && rustup update
RUN cargo install --path .

CMD ["cargo", "run"]
````

## Fichier 'compose.yml'
### _Version pour tester dans le terminal_ :
Avant de déployer sur le serveur le fichier _compose.yml_, il vaut mieux le tester en local pour : repérer et corriger les erreurs, éviter des problèmes en production.

````
services:
  api:
    image: brief21-jb-v2
    networks:
      - app
    ports:
      - "8079:8080"
    environment:
      HOST: 0.0.0.0
      POSTGRES_HOST: db:5432
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    depends_on:
      - db

  db:
    image: postgres:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - db
      - app

volumes:
  db_data:

networks:
  app:
  db:
````
### _Version sur le serveur_
Après les tests en local, on peut copier le fichier sur le serveur avec quelques adaptations :
- ajout de traefik (pour gérer le reverse proxy, le routage de manière automatique et centralisée)
- suppression des ports (utiles pour les tests en local)
````
services:
  api:
    image: registry.nocturlab.fr/jbouhet/brief21-jb-v2
    labels:
      - traefik.enable=true
      - traefik.http.routers.jb-api.rule=Host(`api-jb.nocturlab.fr`)
      - traefik.http.services.jb-api.loadbalancer.server.port=8080
    networks:
      - traefik
      - app
    environment:
      HOST: 0.0.0.0
      POSTGRES_HOST: db:5432
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    depends_on:
      - db

  db:
    image: postgres:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - db
      - app

volumes:
  db_data:

networks:
  app:
  db:
  traefik:
    external: true
    name: traefik_default
````

