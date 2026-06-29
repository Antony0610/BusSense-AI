# BusSense AI Passenger App Documentation

The passenger app is a mobile-first single page application in `mobile_app/index.html`.

## Screens

- Home: source/destination search, current time/location, nearby buses, and map.
- Live: live occupancy cards and occupancy trend chart from `/api/buses` and `/api/occupancy`.
- AI Picks: less-crowded, faster, seat-available recommendations plus alternatives for overcrowded buses.
- Sustainability: CO₂ and fuel savings visualized from `/api/stats`.
- Profile: favorites, accessibility controls, emergency actions, and travel history.

## Screenshot / Preview

A lightweight SVG preview is included at `mobile_app/assets/images/app-preview.svg`. Run the Flask backend and open `mobile_app/index.html` in a browser for the interactive version.
