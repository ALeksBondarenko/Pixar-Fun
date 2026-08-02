<h1 align="center">Movie Explorer</h1>

<p align="center">A non-commercial educational iOS application built with SwiftUI and the TMDB API.</p>

> [!IMPORTANT]
> This is an independent, non-commercial educational and portfolio project.
> It is not affiliated with TMDB.

<img src="/Media/preview.gif" align="right" width="320"/>

## Project Status

This repository is a non-commercial educational and portfolio project.

It is not distributed as a commercial product and does not contain advertising,
subscriptions, paid functionality, or other monetization.

## Features

- List of movies
- Movie detail screen
- List of favorite movies
- Watch later movies
- Network Client
- Pagination
- Dependency injection
- Clean architecture

## Tech Stack

- Swift
- SwiftUI
- Async/Await
- Swift Concurrency
- Dependency Injection via Swinject

External libraries:

- Swinject

## Architecture

The project follows **Clean Architecture** principles.

Layers:

Presentation  
→ ViewModels (MVVM)

Domain  
→ Repository protocols

Data  
→ Repository implementations  
→ RemoteDataSource (TMDB API)

UI never communicates with the network directly.  
All data flows through the repository layer.

---

## Data Flow

<img src="/Media/architecture.png" width="320"/>

---

## Data Source and TMDB Attribution

This project uses the TMDB API to retrieve movie, person, image, favorites,
authentication, and watchlist data.

This product uses the TMDB API but is not endorsed or certified by TMDB.

TMDB data and images remain subject to the rights and terms of their respective owners.

https://www.themoviedb.org

---

## Media and API Data

The repository does not intentionally bundle third-party movie posters,
film frames, character artwork, or trailers.

Movie metadata and image URLs are requested from TMDB at runtime.

Availability and permitted use of third-party media remain subject to the
rights and terms of their respective owners.

---

## Trademark Notice

Movie titles, character names, posters, images, and related
properties are trademarks or copyrighted works of their respective owners.

Their use in this project is solely descriptive and is intended to demonstrate
a non-commercial software development project.

The names Movie Explorer and MovieExplorer are independent project names and
do not imply affiliation with any third-party rights holder.

---

## Dependencies

The project uses the following third-party library:

- Swinject — dependency injection container

All other functionality relies on native Apple frameworks.

---

## How to Run

1. Clone the repository

```
git clone https://github.com/ALeksBondarenko/MovieExplorer-iOS.git
```

2. Open the project in Xcode

3. Add your TMDB API key

```
Copy the template:

Secrets.xcconfig.example → Secrets.xcconfig

Open Secrets.xcconfig and set:

API_KEY = YOUR_TMDB_API_KEY
```

Secrets.xcconfig is listed in `.gitignore` and must never be committed.

4. Favorites and watch list require signing in with your TMDB account (Favorite/WatchList tabs prompt to log in via TMDB when needed) — no extra setup needed for that beyond the API key above.

5. Run the project on a simulator or device.

---

## Requirements

- Xcode 26+
- iOS 23+

---

## License

The original source code in this repository is licensed under the Apache License 2.0.

The license applies only to the original source code created for this project.
It does not grant any rights to third-party trademarks, movie titles, character
names, posters, images, API data, logos, or other copyrighted materials.

See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for details.

---

## Notes

This project is a demo application created for educational purposes and to showcase code structure and architecture.

---

## Author

Aleksandr Bondarenko
