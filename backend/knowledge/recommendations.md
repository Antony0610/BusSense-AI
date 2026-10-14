# BusSense AI — Multi-Factor Recommendation Engine
Document ID: KB-RECOMMENDATION
Category: RECOMMENDATION_LOGIC
Version: 1.1.0
Last Verified: October 2026

## 1. Recommendation Scoring Framework
BusSense AI recommends transit options using a multi-factor normalized utility score ($0.0 - 100.0$) rather than simple arrival time:
1. **Arrival ETA Component ($s_{\text{eta}}$):** Rewards earlier vehicle arrival within a 30-minute window.
2. **Current Occupancy Component ($s_{\text{crowd}}$):** Rewards vehicles with lower cabin load and available seating.
3. **Predicted Occupancy Component ($s_{\text{pred}}$):** Incorporates H9 Ridge demand forecasts matching the journey duration window, discounted when prediction confidence is low.
4. **Journey Duration Component ($s_{\text{time}}$):** Rewards quicker travel time, including an 8-minute corridor advantage for dedicated bus lanes (e.g. Banerji Road transit priority lane).
5. **Transit Fare Component ($s_{\text{fare}}$):** Rewards economical tariffs.
6. **Corridor Reliability:** Priority lane multiplier ($1.03\times$).

## 2. Preference Modes
Commuters can customize recommendation weighting:
- **`balanced` (Default):** Balanced trade-off across arrival time (25%), crowd (25%), prediction (20%), journey duration (15%), and fare (15%).
- **`fastest`:** Heavily prioritizes earliest ETA (45%) and shortest travel time (25%).
- **`least_crowded`:** Heavily prioritizes lowest current occupancy (40%) and lowest predicted crowd (30%).
- **`lowest_fare`:** Heavily prioritizes lowest transit tariff (50%).

## 3. Zero Hardcoded Winner Policy
- There are NO static or hardcoded preferences for Bus 205 or any specific bus.
- When Bus 205 is crowded or delayed, the engine recommends alternative vehicles (e.g. Bus 14A or Bus 12).
- The winning recommendation dynamically updates as live occupancy, ETAs, predictions, or destinations change.

## 4. Truth Labels & Human Decision
- Recommendations are stamped strictly with `RECOMMENDATION`.
- Suggestions are informational aids for passengers and dispatchers; the system NEVER performs autonomous bus dispatch or automatic route diversion without human clearance.
