# UC Maps

##Features and Functionality:

**Application Structure:** Our app is built using Flutter, a popular framework for developing cross-platform mobile applications. It utilizes various Dart libraries and packages for mapping, geolocation, HTTP requests, and UI components.

**Map Display and Interaction:** This app additionally employs flutter maps for displaying maps and supports user interactions like zooming and tapping to identify buildings or rooms. The map tiles are fetched from an external service, and it uses a dark theme base map.

**Search and Filter:** Users can search for specific buildings or rooms, with support for filtering based on categories like bathrooms, offices, and classrooms. Search results update the displayed polygons and markers on the map.

**Geolocation Features:** Our app integrates geolocation to track the user's current position, mark it on the map, and offer navigation instructions to selected destinations within the campus boundaries.

**Dynamic Content Loading:** Our app supports over 8 million lines of Json, of which Building and room data are dynamically loaded from, allowing for detailed information about various locations, including the names, descriptions, and polygon shapes on the map all at the tap of a button.

**Navigation and Directions:** Additionally it calculates routes and directions for walking, providing users with step-by-step navigation instructions, estimated arrival times (ETAs), and dynamic updates based on the user's movement. Additionally we Utilized openStreetMap and packages like dio for HTTP requests, geolocator for accessing location services, and flutter_polyline_points for decoding polyline strings for navigation routes. Even furthermore, We implemented features for determining user location permission status, calculating distances and centroids for polygons, and filtering visible markers based on zoom levels.

Overall, the application it meant to act as a general solution to the issue with the size of the campus up at UC, and stands as of right now as a direct upgrade to space.uc.edu by providing almost all information there and more! We hope you enjoy!!!
