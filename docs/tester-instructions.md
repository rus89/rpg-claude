# Tester Instructions for Google Play Closed Testing

## App 1: GeoAgro Srbija

### What is it?
A free Android app that visualizes Serbian agricultural data from the government's open data portal (data.gov.rs). It shows farm statistics, trends, and geographic distribution across 170+ Serbian municipalities.

### Requirements
- Android device (not an emulator)
- Internet connection required — the app fetches live data at startup

### First launch
When you first open the app, you'll see a loading screen while data is downloaded from data.gov.rs. This can take up to 30 seconds depending on your connection. Once loaded, you'll land on the overview dashboard.

### Screens to test

**1. Pregled (Overview)**
- Summary cards showing national farm statistics
- Bar chart of farm types (organizational forms)
- Top 5 and bottom 5 municipality rankings
- Farm size distribution section
- Age structure section
- Try tapping different elements

**2. Opštine (Municipalities)**
- Search for municipalities by name using the search field
- Try the clear (X) button after typing
- Tap any municipality to see its detail screen
- Check the trend line chart, organizational form breakdown, size and age data
- Try navigating back and selecting a different municipality

**3. Trendovi (Trends)**
- Switch between datasets using the dropdown at the top
- Filter by municipality
- Tap the category filter chips to toggle different farm types on/off
- Check that the chart updates correctly

**4. Mapa (Map)**
- Pan and zoom around the map of Serbia
- Tap on any coloured municipality to see its data overlay
- Try the metric selector (top of screen) to switch between: farm count, average size, average age, % young operators
- Check that colours update when switching metrics
- Look for grey municipalities — these have 0 recorded farms (not a bug)

**5. O aplikaciji (About)**
- Tap the link to the government data source — it should open in your browser
- Read through the screen guide

### What to look for
- Does the app load reliably? Any crashes or blank screens?
- Do all municipalities display correctly on the map?
- Does search work with Serbian characters (č, š, ž, ć, đ)?
- Is the text readable? Any layout issues on your screen size?
- Does navigation between screens feel smooth?
- Any data that looks wrong or missing?
- How does it behave on slow/unstable internet?
- Try rotating your device — does the layout adapt?

### Known behaviors (not bugs)
- Grey municipalities on the map = 0 recorded farms in that municipality
- Initial load can be slow on 3G/slow connections
- Some municipality names in the raw data have diacritics replaced with "?" — the app handles this internally

---

## App 2: Udahni

### What is it?
A free Android app that shows current pollen levels for Serbian cities using real-time data from Serbia's pollen monitoring network. Useful for people with allergies.

### Requirements
- Android device (not an emulator)
- Internet connection required — the app fetches live pollen data

### What to test
- Does the app load and display pollen data for your city?
- Is the data up to date?
- Try switching between different cities
- Check allergen types — are they displayed clearly?
- Any crashes, blank screens, or loading issues?
- How does it behave on slow/unstable internet?
- Is the UI clear and easy to understand?
- Try rotating your device

### Feedback
For both apps, please provide honest, specific feedback:
- What worked well
- What confused you or felt broken
- What you'd like to see improved
- Your device model and Android version (helps with debugging)

Thank you for testing!
