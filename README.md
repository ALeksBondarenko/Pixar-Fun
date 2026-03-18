<h1 align="center">Pixar Fun iOS App</h1>

A small demo iOS application that displays movies produced by Pixar using the TMDB API.

<img src="/Media/preview.gif"  align="right" width="320"/>

## Features

- List of Pixar movies
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

## API

Movie data is provided by:

The Movie Database (TMDB)

https://www.themoviedb.org

---

## Dependencies

The project uses the following third-party library:

- Swinject — dependency injection container

All other functionality relies on native Apple frameworks.

---

## How to Run

1. Clone the repository

```
git clone https://github.com/ALeksBondarenko/Pixar-Fun.git
```

2. Open the project in Xcode

3. Add your TMDB API key

```
Create a file: 

Secrets.xcconfig

and add:

API_KEY = YOUR_API_KEY

ACCOUNT_ID = YOUR_ACCOUNT_ID
```

4. Run the project on a simulator or device.

---

## Requirements

- Xcode 26+
- iOS 23+

---

## Notes

This project is a demo application created for educational purposes and to showcase code structure and architecture.

---

## Author

Aleksandr Bondarenko
