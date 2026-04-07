# Classification Property Flow Diagram

## Property Transfer Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     CLASSIFICATION OBJECTS                               │
│                     (Custom Objects in Vault)                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
            ┌───────▼────────┐             ┌───────▼────────┐
            │  CLASS OBJECT  │             │  TERM OBJECT   │
            │                │             │                │
            │  Properties:   │             │  Properties:   │
            │  • Code        │             │  • Code        │
            │  • Level 1-4   │             │  • Term DE     │
            │  • Standard    │             │  • Term EN     │
            │  • Custom UDPs │             │  • Term FR     │
            │                │             │  • Term IT     │
            │                │             │  • Term ES ✨  │
            │                │             │  • Custom UDPs │
            └────────────────┘             └────────────────┘
                    │                               │
                    │                               │
                    └───────────┬───────────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  mSelectClassification │
                    │  (Merge Properties)    │
                    │                        │
                    │  FILTERING:            │
                    │  ✓ Include: Code ✨    │
                    │  ✗ Exclude: Levels 1-4 │
                    │  ✗ Exclude: Standard   │
                    │  ✗ Exclude: Term names │
                    │  ✓ Include: Custom UDPs│
                    │                        │
                    │  MAPPING (if checked): │
                    │  Term DE → Title DE    │
                    │  Term EN → Title       │
                    │  Term FR → Title FR    │
                    │  Term IT → Title IT    │
                    │  Term ES → Title ES ✨ │
                    └────────────────────────┘
                                │
                                │
                    ┌───────────▼────────────┐
                    │  mApplyClassification  │
                    │  (Write to File)       │
                    └────────────────────────┘
                                │
                                │
                ┌───────────────▼────────────────────┐
                │          FILE PROPERTIES            │
                │                                     │
                │  Transferred Properties:            │
                │  • Code ✨ (NEW)                    │
                │  • Title DE, EN, FR, IT, ES ✨      │
                │  • Custom UDPs                      │
                │                                     │
                │  NOT Transferred:                   │
                │  • Segment (Level 1)                │
                │  • Main Group (Level 2)             │
                │  • Group (Level 3)                  │
                │  • Sub Group (Level 4)              │
                │  • Class                            │
                │  • Standard                         │
                │  • Level Code                       │
                │  • Comments, CommentsDE             │
                └─────────────────────────────────────┘
```

---

## Property Priority Rules

When both Class Object and Term Object are assigned:

```
┌─────────────────┐
│  CLASS OBJECT   │──┐
│  Code: "CLS-001"│  │
│  Prop1: "A"     │  │  ┌─────────────────────────┐
│  Prop2: "B"     │  │  │   MERGED PROPERTIES     │
└─────────────────┘  │  │                         │
                     ├──│  Code: "TRM-002" ✓      │──► FILE
┌─────────────────┐  │  │  Prop1: "X" ✓          │
│  TERM OBJECT    │──┘  │  Prop2: "B" ✓          │
│  Code: "TRM-002"│     │  Prop3: "Y" ✓          │
│  Prop1: "X"     │     │                         │
│  Prop3: "Y"     │     │  TERM TAKES PRIORITY!   │
└─────────────────┘     └─────────────────────────┘
```

**Rule**: Term properties override Class properties when both exist.

---

## Exclusion List Logic

The `$Global:mClsPropNames` array defines which properties should NOT be transferred:

```
┌──────────────────────────────────────────────────────────────┐
│  $Global:mClsPropNames (EXCLUSION LIST)                      │
│                                                               │
│  Properties in this list are FILTERED OUT:                   │
│  ─────────────────────────────────────────────────────       │
│  ✗ Adsk.QS.ClsLevel_01     (Segment)                        │
│  ✗ Adsk.QS.ClsLevel_02     (Main Group)                     │
│  ✗ Adsk.QS.ClsLevel_03     (Group)                          │
│  ✗ Adsk.QS.ClsLevel_04     (Sub Group)                      │
│  ✗ Adsk.QS.ClsObject       (Class)                          │
│  ✗ Adsk.QS.ClsStandard     (Standard)                       │
│  ✗ ClassTerms_09           (Term DE - hierarchy name)        │
│  ✗ ClassTerms_10           (Term EN - hierarchy name)        │
│  ✗ ClassTerms_11           (Term FR - hierarchy name)        │
│  ✗ ClassTerms_12           (Term IT - hierarchy name)        │
│  ✗ ClassTerms_12a          (Term ES - hierarchy name) ✨     │
│  ✗ Adsk.QS.ClsLevelCode    (Level Code)                     │
│  ✗ Comments                (Comments)                        │
│  ✗ CommentsDE              (German Comments)                 │
│                                                               │
│  REMOVED FROM EXCLUSION LIST (NOW TRANSFERRED):              │
│  ─────────────────────────────────────────────────────       │
│  ✓ Adsk.QS.ClsCode         (Code) ✨ CHANGE #2              │
│                                                               │
│  All OTHER properties are automatically transferred!         │
└──────────────────────────────────────────────────────────────┘
```

---

## User Interface Flow

### 1. Classification Selection Dialog

```
┌─────────────────────────────────────────────────────────────┐
│  Select Classification                                  [X] │
├─────────────────────────────────────────────────────────────┤
│  Standard: [IEC 61355 ▼]                                    │
│                                                              │
│  [Reset] [Segment ▼] [Main Group ▼] [Group ▼] [Sub Group ▼]│
│                                                              │
│  ┌─ Class Level 1 ──────────────────────────────────────┐  │
│  │ Class Object: [Electric Motors ▼]                     │  │
│  │ Class Term:   [Motor 3-Phase ▼]                       │  │
│  │  ┌─ Class Level 2 ───────────────────────────────┐   │  │
│  │  │ ...                                            │   │  │
│  └──└────────────────────────────────────────────────┘───┘  │
│                                                              │
│  ┌─ Class Object Properties ─────────────────────────────┐  │
│  │ Property Name        │ Property Value                  │  │
│  │─────────────────────┼──────────────────────────────────│ │
│  │ Code ✨              │ PUMP-001                        │  │
│  │ Material             │ Stainless Steel                 │  │
│  │ Weight               │ 50                              │  │
│  └──────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌─ Class Term Properties ───────────────────────────────┐  │
│  │ Property Name        │ Property Value                  │  │
│  │─────────────────────┼──────────────────────────────────│ │
│  │ Code ✨              │ TRM-PUMP-3PHASE                 │  │
│  │ Term DE              │ Pumpe                           │  │
│  │ Term EN              │ Pump                            │  │
│  │ Term ES ✨           │ Bomba                           │  │
│  │ Power                │ 5.5 kW                          │  │
│  └──────────────────────────────────────────────────────────┘│
│                                                              │
│  ☑ Copy Term → Title Values (Multi-Languages)               │
│                                                              │
│  [Help]                               [Select Classification]│
└─────────────────────────────────────────────────────────────┘
```

### 2. Result on File Properties

After clicking "Select Classification", the file receives:

```
┌─────────────────────────────────────────────────────────────┐
│  FILE PROPERTIES (After Classification Applied)             │
├─────────────────────────────────────────────────────────────┤
│  Property Name        │ Property Value                      │
│──────────────────────┼──────────────────────────────────────│
│  Code ✨              │ TRM-PUMP-3PHASE (from Term)         │
│  Title ✨             │ Pump (from Term EN)                 │
│  Title DE ✨          │ Pumpe (from Term DE)                │
│  Title ES ✨          │ Bomba (from Term ES)                │
│  Material             │ Stainless Steel (from Class)        │
│  Weight               │ 50 (from Class)                     │
│  Power                │ 5.5 kW (from Term)                  │
│──────────────────────────────────────────────────────────────│
│  NOT INCLUDED (filtered out):                               │
│  • Segment, Main Group, Group, Sub Group                    │
│  • Class name                                               │
│  • Standard (IEC 61355)                                     │
│  • Level Code                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Functions

### mGetClsPrpNames()
- **Purpose**: Get property names from Class Object
- **Filter**: Excludes properties in `$Global:mClsPropDefIds`
- **Returns**: Dictionary of PropDefId → DisplayName
- **Impact**: Code ✨ is now included (not in exclusion list)

### mGetClsDfltValues()
- **Purpose**: Get default values from Class Object for preview
- **Filter**: Only includes properties NOT in `$Global:mClsPropNames`
- **Impact**: Code ✨ now appears in preview grid

### mGetTermDfltValues()
- **Purpose**: Get default values from Term Object for preview
- **Filter**: Only excludes `$Global:mClsLevelNames` (Level 1-4)
- **Impact**: Code ✨ and Term ES ✨ both appear in preview

### mSelectClassification()
- **Purpose**: Merge Class and Term properties for file transfer
- **Logic**: 
  1. Add all Class properties
  2. Add/override with Term properties (Term priority)
  3. Apply Term → Title mapping if checkbox checked
- **Impact**: Code ✨ transferred; Term ES ✨ mapped to Title ES

### mApplyClassification()
- **Purpose**: Write merged properties to file
- **Impact**: Code ✨ now written to file properties

---

## Backward Compatibility

✓ **Existing classifications**: Continue to work without modification  
✓ **Missing properties**: Optional - only populated if defined  
✓ **Old workflows**: No breaking changes  
✓ **New features**: Available immediately for new classifications  

---

## Migration Path

No migration required! Changes are additive:

1. **Term ES**: Start using immediately in new/edited Terms
2. **Code**: Existing Class/Term objects can keep Code empty or populate as needed
3. **Files**: Will receive Code when re-classified or newly classified

---

*For detailed implementation, see:*
- *TERM_ES_IMPLEMENTATION_SUMMARY.md*
- *CODE_PROPERTY_IMPLEMENTATION.md*
- *CLASSIFICATION_CHANGES_SUMMARY.md*
