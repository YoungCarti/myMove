# Physical Prototype Design Guide for myMove Parking System

## Overview

You'll build a **tabletop parking model** that demonstrates your system's functionality. This is perfect for FYP presentations and exhibitions!

---

## Materials Needed 🛠️

### Base Structure:
- [ ] **Large cardboard box** (40cm × 30cm × 20cm recommended)
  - Shoebox works for 2 spots
  - Pizza box for 4 spots
  - Or buy foam board from bookstore (RM 10-15)
- [ ] **Ruler and pencil**
- [ ] **Craft knife / scissors**
- [ ] **Glue gun** or strong tape
- [ ] **Black/gray paint** or paper (for road markings)
- [ ] **White paint/marker** (for parking lines)

### Electronics:
- [ ] 1× ESP32 board
- [ ] 4× HC-SR04 ultrasonic sensors
- [ ] 1× Breadboard
- [ ] Jumper wires (20-30 pieces)
- [ ] 1× Power bank or USB cable

### Decorations (Optional but Impressive):
- [ ] Small toy cars (Hot Wheels size - RM 5-10 each)
- [ ] Miniature trees/buildings (craft store)
- [ ] LED strips for lighting (RM 15-20)
- [ ] Printed building sign ("Menara BAC")

---

## Design Layout 📐

### Top View of Parking Model:

```
╔════════════════════════════════════════╗
║  MENARA BAC - FLOOR 1 PARKING          ║
╠════════════════════════════════════════╣
║                                        ║
║  ┌──────┐  ┌──────┐  ┌──────┐  ┌────┐ ║
║  │ [S1] │  │ [S2] │  │ [S3] │  │[S4]│ ║  ← Sensors mounted
║  │  ↓   │  │  ↓   │  │  ↓   │  │ ↓  │ ║     on top/ceiling
║  ├──────┤  ├──────┤  ├──────┤  ├────┤ ║
║  │ CAR  │  │      │  │ CAR  │  │    │ ║
║  │ A01  │  │  A02 │  │ A03  │  │A04 │ ║
║  └──────┘  └──────┘  └──────┘  └────┘ ║
║                                        ║
║    [ESP32 + Breadboard]                ║
║         mounted on side                ║
╚════════════════════════════════════════╝

Legend:
[S1-S4] = Ultrasonic sensors
A01-A04 = Parking spot numbers
```

---

## Step-by-Step Build Instructions 🔨

### Step 1: Build the Base (1 hour)

**Option A: Foam Board (Recommended)**

1. Buy A3 foam board (RM 10-15 from Popular/bookstore)
2. Cut base: 40cm × 30cm
3. Cut walls: 
   - 2 pieces: 40cm × 10cm (long sides)
   - 2 pieces: 30cm × 10cm (short sides)
4. Glue walls to base with hot glue

**Option B: Cardboard Box**

1. Find sturdy box (e.g., shoe box, pizza box)
2. Remove lid or cut one side open
3. Reinforce corners with tape

---

### Step 2: Create Parking Layout (1 hour)

**Mark Parking Spots:**

```
Each spot: 8cm × 12cm (scaled for toy cars)

Measurements:
├─ 8cm ─┤ 1cm ├─ 8cm ─┤ 1cm ├─ 8cm ─┤ 1cm ├─ 8cm ─┤
┌────────┬────┬────────┬────┬────────┬────┬────────┐
│        │    │        │    │        │    │        │
│  A01   │    │  A02   │    │  A03   │    │  A04   │
│        │    │        │    │        │    │        │
└────────┴────┴────────┴────┴────────┴────┴────────┘
  Spot 1  Gap  Spot 2  Gap  Spot 3  Gap  Spot 4
```

**Materials:**
- Paint base gray (asphalt color)
- Use white paint/tape for parking lines
- Write spot numbers with marker (A01, A02, A03, A04)

**Pro Tip:** Print parking layout on paper and glue it down!

---

### Step 3: Mount Sensors (1 hour)

**Sensor Positioning:**

```
Side View:

    Ceiling/Top Panel
    ┌─────────────────────────────────┐
    │  [Sensor]     [Sensor]          │ ← Sensors taped here
    │     ↓            ↓              │
    └─────┬────────────┬──────────────┘
          │            │
      10-15cm      10-15cm  ← Height above parking spot
          │            │
    ┌─────▼────┐  ┌────▼─────┐
    │  [Car]   │  │ [Empty]  │
    └──────────┘  └──────────┘
      Spot A01       Spot A02
```

**Mounting Methods:**

**Method 1: Top Mount (Recommended)**
- Cut small holes in top panel for sensors
- Sensors point DOWN at parking spots
- Secure with hot glue or zip ties
- Wires run along inside of walls

**Method 2: Overhead Frame**
- Create a "ceiling" from cardboard strip
- Mount sensors on underside
- Suspend 10-15cm above spots
- More professional look

**Height Considerations:**
- Too high (>20cm): May not detect small toy cars
- Too low (<5cm): May always show occupied
- **Optimal: 10-15cm above parking surface**

---

### Step 4: Wire Everything (1-2 hours)

**Wiring Diagram for 4 Sensors:**

```
                    ESP32 (mounted on side)
        ┌───────────────────────────────────┐
        │  VIN GND  5  18  19  21  22  23  25  26 │
        └───┬───┬───┬───┬───┬───┬───┬───┬───┬─┘
            │   │   │   │   │   │   │   │   │   
            │   │   └───┼───┘   │   └───┼───┘
            │   │       │       │       │       
     Red ───┘   └─── Black     │       │       
     (Power)    (Ground)       │       │       
                                │       │       
        ┌───────────────────────┼───────┼───────┐
        │   ┌───────────────────┼───────┼─────┐ │
        │   │   ┌───────────────┘       │   ┌─┘ │
        │   │   │   ┌───────────────────┘   │   │
        │   │   │   │                       │   │
    ┌───▼───▼───▼───▼──┐  ┌──────┐  ┌──────▼───▼──┐
    │    Sensor 1      │  │ S2   │  │  Sensor 3   │ ...
    │ VCC TRIG ECHO GND│  │      │  │             │
    └──────────────────┘  └──────┘  └─────────────┘
        A01                 A02           A03
```

**Wire Management Tips:**
- Use different colored wires (Red=Power, Black=Ground, Other=Signal)
- Run wires along edges of box (use tape to secure)
- Label each wire with masking tape
- Leave some slack for adjustments

---

### Step 5: Mount Electronics (30 minutes)

**ESP32 Placement:**

```
Side View of Box:

    ┌─────────────────────────────┐
    │ Sensors on top/ceiling      │
    │                             │
    ├─────────────────────────────┤
    │                             │
    │  Parking Spots              │
    │                             │
    └─────┬───────────────────────┘
          │
    ┌─────▼──────┐
    │ ESP32 +    │ ← Mounted on outside
    │ Breadboard │    or back of box
    │ [USB Cable]│
    └────────────┘
```

**Mounting Options:**

1. **Double-sided tape** on back of box
2. **Velcro strips** (can remove for adjustments)
3. **Small shelf** glued inside box
4. **External platform** next to box

**Power Cable:**
- Run USB cable out the side/back
- Connect to laptop or power bank
- Tape cable to table (won't pull during demo)

---

## Decoration & Professional Touches ✨

### Level 1: Basic (30 minutes)
- [ ] Paint/color the parking layout
- [ ] Add spot numbers (A01-A04)
- [ ] Clean, taped wires

### Level 2: Good (1 hour)
- [ ] Add building sign "MENARA BAC - FLOOR 1"
- [ ] Paint box exterior (looks professional)
- [ ] Add directional arrows on parking spots
- [ ] Use toy cars for occupied spots

### Level 3: Excellent (2 hours) ⭐
- [ ] LED indicators for each spot (Green=Available, Red=Occupied)
- [ ] Miniature trees/barriers around parking
- [ ] Printed floor plan reference
- [ ] QR code stickers on toy cars
- [ ] Acrylic/clear plastic cover (looks premium!)

---

## Testing Your Prototype 🧪

### Test 1: Individual Sensor Test

1. Power on ESP32
2. Open Serial Monitor
3. Check each sensor reads correctly:
   ```
   A01: 12 cm - AVAILABLE
   A02: 45 cm - AVAILABLE  
   A03: 8 cm - OCCUPIED    ← Toy car placed here
   A04: 35 cm - AVAILABLE
   ```

### Test 2: Car Placement Test

1. Place toy car in spot A01
2. Wait 2 seconds
3. Check Firebase: `spots/A01/occupied` should be `true`
4. Remove car
5. Check Firebase: `spots/A01/occupied` should be `false`

**Repeat for all 4 spots!**

### Test 3: App Integration Test

1. Open Flutter app on phone
2. Select "Prototype Demo" building
3. Should see 4 spots with real-time status
4. Place/remove cars, watch app update! 🎉

---

## Sensor Calibration for Small Scale ⚙️

Since you're using toy cars (smaller than real cars), adjust detection threshold:

```cpp
// In your code, change this:
#define CAR_DETECTED_DISTANCE 15  // 15cm for toy cars

// Test and adjust based on your setup:
// - Measure distance with NO car: e.g., 25cm
// - Measure distance WITH car: e.g., 8cm
// - Set threshold between them: e.g., 15cm
```

**Testing:**
1. Place sensor 10-15cm above spot
2. Measure distance to empty spot
3. Place toy car, measure again
4. Set threshold midway between values

---

## Demo Day Setup 🎭

### What to Bring:

**Hardware:**
- [ ] Complete prototype model
- [ ] Charged power bank (or USB cable + adapter)
- [ ] Spare USB cable (backup!)
- [ ] 4 toy cars (2 as backups)

**Software:**
- [ ] Laptop with Serial Monitor ready
- [ ] Phone with app installed
- [ ] Firebase Console open (show real-time database)

**Documentation:**
- [ ] Printed system architecture diagram
- [ ] QR code cards (show QR feature)
- [ ] Project poster (optional)

### Demo Script (3 minutes):

**Minute 1: Introduction**
> "This is myMove, a smart parking system for Malaysia. The prototype demonstrates real-time parking detection using IoT sensors."

**Minute 2: Live Demo**
1. Show app with all spots available
2. Place toy car in A01
3. Point out: "App updates in real-time - A01 now occupied"
4. Remove car: "And now available again"
5. Show Firebase updating live

**Minute 3: QR Feature**
1. Show QR code on toy car
2. Scan with app
3. Demonstrate contact options
> "This solves double-parking without sharing phone numbers"

---

## Budget Breakdown 💰

### Minimum Setup (RM 100-150):

| Item | Quantity | Price (RM) |
|------|----------|-----------|
| ESP32 | 1 | 30 |
| HC-SR04 Sensors | 4 | 28 |
| Breadboard | 1 | 8 |
| Jumper Wires | 1 pack | 5 |
| Foam Board | 2 sheets | 20 |
| Paint/Markers | - | 15 |
| Toy Cars | 4 | 20 |
| **TOTAL** | | **126** |

### Professional Setup (RM 200-250):

Add to above:
- LED indicators: RM 20
- Acrylic cover: RM 30
- Miniature decorations: RM 20
- Better toy cars: RM 30

---

## Advantages of Prototype Model 🌟

### For Your FYP:

✅ **Portable**: Carry to presentations
✅ **Controllable**: No real parking lot needed
✅ **Repeatable**: Same demo every time
✅ **Low Cost**: ~RM 150 vs thousands for real installation
✅ **Safe**: No electrical/construction permits needed
✅ **Impressive**: Shows you can build hardware
✅ **Professional**: Companies do this for demos too!

### For Examiners:

> "This student didn't just make an app - they built a working physical prototype demonstrating hardware-software integration!"

**This impresses examiners!**

---

## Photos to Take for Thesis 📸

Document your build:

1. **Before**: Empty box/materials
2. **During**: Wiring process
3. **Complete**: Finished model (multiple angles)
4. **Close-ups**: Sensor mounting, wiring
5. **Testing**: Serial monitor showing data
6. **Demo**: Toy car triggering sensor
7. **App**: Phone showing real-time updates
8. **Firebase**: Database updating live

**These photos go in your thesis Chapter 4 (Results)!**

---

## Troubleshooting Common Issues 🔧

### Problem: Sensor always shows "Occupied"
**Cause**: Mounted too low or pointing at box bottom
**Fix**: Raise sensor to 10-15cm height

### Problem: Sensor never detects toy car
**Cause**: Car too small or sensor too high
**Fix**: Lower sensor or use larger toy cars

### Problem: Readings fluctuate wildly
**Cause**: Loose wires or sensor vibration
**Fix**: Secure all connections, stabilize sensors

### Problem: Only some sensors work
**Cause**: Pin conflicts or wiring error
**Fix**: Check pin assignments match code

---

## Timeline to Build Prototype ⏱️

| Day | Task | Time |
|-----|------|------|
| 1 | Order materials | 1 hour |
| 2-3 | Wait for delivery | - |
| 4 | Build base structure | 2 hours |
| 5 | Mount sensors, wire ESP32 | 3 hours |
| 6 | Test & calibrate | 2 hours |
| 7 | Decorate & polish | 2 hours |

**Total: Can be done in 1 week!**

---

## Pro Tips from Experience 💡

1. **Test sensors BEFORE mounting**: Make sure they work on breadboard first

2. **Use removable mounting**: Velcro > hot glue (easier to adjust)

3. **Cable management is important**: Messy wires = unprofessional look

4. **Have backup toy cars**: In case one goes missing during demo

5. **Practice your demo**: Know exactly what to say in 3 minutes

6. **Bring extension cord**: Don't depend on venue having nearby outlet

7. **Take video before demo day**: If live demo fails, you have proof it worked

---

## Scaling Story for Thesis 📝

When examiners ask: "How does this scale to real parking lots?"

**Your Answer:**
> "This prototype uses 1 ESP32 for 4 spots to demonstrate the concept cost-effectively. In production:
> 
> - Each floor section (10-20 spots) would have 1-2 ESP32 units
> - Sensors would be ceiling-mounted at 2-3 meters
> - Industrial-grade components (IP65 rated)
> - Powered by building electrical system
> - Same Firebase architecture scales to thousands of spots
> 
> The prototype validates the core technology at 1/10th the cost of a real installation."

**This shows you understand real-world deployment!**

---

## Final Checklist ✅

### Before Demo Day:

- [ ] All 4 sensors detect reliably (>95% accuracy)
- [ ] Firebase updates within 2 seconds
- [ ] App connects and displays real-time data
- [ ] Prototype looks clean and professional
- [ ] Wires are secured and organized
- [ ] Practiced 3-minute demo speech
- [ ] Backup power bank charged
- [ ] Photos/videos documented
- [ ] Can explain every component

### Backup Plans:

- [ ] If WiFi fails: Use phone hotspot
- [ ] If sensor fails: Have manual override script
- [ ] If app crashes: Show Firebase Console directly
- [ ] If everything fails: Show pre-recorded video

---

## Conclusion 🎯

Your prototype approach is **PERFECT** for FYP! It's:
- Practical (can actually build)
- Affordable (RM 150 budget)
- Impressive (physical + digital)
- Portable (demo anywhere)
- Scalable (clear path to production)

**You've got this!** 💪

Start building this week and you'll have a working demo in 7 days!
