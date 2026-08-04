//
//  DecoderTests.swift
//  Movie ExplorerTests
//

import Testing
@testable import Movie_Explorer
import Foundation

struct DecoderTests {

    private func json(_ string: String) -> Data {
        Data(string.utf8)
    }

    @Test
    func testMovieDecodesEmptyReleaseDateAsNil() throws {
        let data = json("""
        {
            "id": 1,
            "title": "Untitled Project",
            "overview": "",
            "poster_path": null,
            "release_date": ""
        }
        """)

        let movie: Movie = try Decoder().decode(data)

        #expect(movie.releaseDate == nil)
        #expect(movie.title == "Untitled Project")
    }

    @Test
    func testMovieDecodesValidReleaseDate() throws {
        let data = json("""
        {
            "id": 1,
            "title": "Toy Story",
            "overview": "",
            "poster_path": null,
            "release_date": "1995-11-22"
        }
        """)

        let movie: Movie = try Decoder().decode(data)

        #expect(movie.releaseDate != nil)
    }

    @Test
    func testPageWithOneEmptyReleaseDateStillDecodesTheWholePage() throws {
        let data = json("""
        {
            "page": 1,
            "total_pages": 1,
            "results": [
                {"id": 1, "title": "Announced Movie", "overview": "", "poster_path": null, "release_date": ""},
                {"id": 2, "title": "Toy Story", "overview": "", "poster_path": null, "release_date": "1995-11-22"}
            ]
        }
        """)

        let page: Page = try Decoder().decode(data)

        #expect(page.results.count == 2)
        #expect(page.results[0].releaseDate == nil)
        #expect(page.results[1].releaseDate != nil)
    }

    @Test
    func testMovieDetailsDecodesEmptyReleaseDateAsNil() throws {
        let data = json("""
        {
            "id": 1,
            "title": "Untitled Project",
            "overview": "",
            "genres": [],
            "budget": 0,
            "revenue": 0,
            "status": "Planned",
            "release_date": "",
            "backdrop_path": null,
            "poster_path": null,
            "vote_average": 0
        }
        """)

        let details: MovieDetails = try Decoder().decode(data)

        #expect(details.releaseDate == nil)
    }

    @Test
    func testPersonDecodesEmptyBirthdayAndDeathdayAsNil() throws {
        let data = json("""
        {
            "id": 1,
            "name": "Someone",
            "profile_path": null,
            "biography": "",
            "birthday": "",
            "deathday": "",
            "place_of_birth": null
        }
        """)

        let person: Person = try Decoder().decode(data)

        #expect(person.birthday == nil)
        #expect(person.deathday == nil)
    }

    @Test
    func testPersonDecodesNullDeathdayAsNil() throws {
        let data = json("""
        {
            "id": 1,
            "name": "Someone Alive",
            "profile_path": null,
            "biography": "",
            "birthday": "1990-01-01",
            "deathday": null,
            "place_of_birth": null
        }
        """)

        let person: Person = try Decoder().decode(data)

        #expect(person.birthday != nil)
        #expect(person.deathday == nil)
    }
}
