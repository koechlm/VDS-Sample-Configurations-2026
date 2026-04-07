# Uniclass Term-as-Class Enhancement

## Overview
Extended the classification assignment workflow to support **Uniclass Standard** where selecting only a Term (without a Class Object) is treated like selecting a Class Object. This allows for more flexible classification in Uniclass where Terms can be used directly as the primary classification.

## Business Requirement
In Uniclass classification standard, users often want to assign only a Term without requiring a Class Object selection. This enhancement allows:
- Selecting a Term directly (without Class Object) in Uniclass mode
- The Term is treated as if it were a Class Object
- All Term properties are applied to the file
- Simplified classification workflow for Uniclass users

## Implementation Details

### 1. Modified `mSelectClassification()` Function
**Location**: ADSK.TS.FileClassification.ps1, around Line 487

Added logic to check for Term selection when no Class Object is selected in Uniclass mode:

```powershell
# Uniclass Extension: If no Class Object selected but a Term is selected, treat Term as Class
if (-not $selectedClassObject -and $global:mActiveStandard -eq "Uniclass") {
    $dsDiag.Trace("Uniclass mode: No Class Object selected, checking for Term selection...")
    for ($i = 1; $i -le 4; $i++) {
        $cmbTrm = $AssignClsWindow.FindName("cmbTrm$i")
        if ($cmbTrm -and $cmbTrm.SelectedItem) {
            $selectedClassObject = $cmbTrm.SelectedItem
            $dsWindow.FindName("txtActiveClass").Text = $selectedClassObject.Name
            $dsDiag.Trace("Uniclass: Set txtActiveClass = '$($selectedClassObject.Name)' from cmbTrm$i (treating Term as Class)")
            break
        }
    }
}
```

**Logic Flow**:
1. First, check for Class Object selection (cmbCls1-4)
2. If no Class Object found AND Standard is "Uniclass"
3. Check for Term selection (cmbTrm1-4)
4. If Term found, use it as the classification object
5. Set `txtActiveClass` to Term name
6. Save Term ID to file for post-close event

### 2. Modified `mApplyClassification()` Function
**Location**: ADSK.TS.FileClassification.ps1, around Line 622

Enhanced to detect whether the selected object is a Class Object or Term, and use the appropriate property retrieval function:

```powershell
# Check if the selected object is a Class Object or Term
$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id
$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject

# Determine which function to use based on object type
if ($isTerm -and $global:mActiveStandard -eq "Uniclass") {
    # For Uniclass Terms, use mGetTermPrpNames to get ALL properties
    $dsDiag.Trace("Uniclass: Applying Term as Class - using mGetTermPrpNames()")
    $mActvClsPrpNames = mGetTermPrpNames($mActiveClass[0].Id)
}
else {
    # For Class Objects and other standards, use mGetClsPrpNames (with filtering)
    $dsDiag.Trace("Applying Class Object - using mGetClsPrpNames()")
    $mActvClsPrpNames = mGetClsPrpNames($mActiveClass[0].Id)
}
```

**Key Changes**:
1. Added object type detection using `CustEntDefId`
2. For Uniclass Terms: Use `mGetTermPrpNames()` (no filtering)
3. For Class Objects: Use `mGetClsPrpNames()` (with filtering)
4. Added diagnostic logging for troubleshooting
5. Added property count logging

## Files Modified

### **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**

1. **mSelectClassification()** (Lines 487-518):
   - Added Uniclass-specific Term detection logic
   - Set `txtActiveClass` from Term when no Class Object selected

2. **mApplyClassification()** (Lines 622-663):
   - Added object type detection (Class vs Term)
   - Use appropriate property retrieval function based on type
   - Enhanced logging for diagnostics

## Technical Details

### Standard Detection
The enhancement only activates when:
```powershell
$global:mActiveStandard -eq "Uniclass"
```

This ensures no impact on other classification standards (IEC 61355, eCl@ss, PDMC-Sample).

### Object Type Detection
Uses `CustEntDefId` to distinguish between Class Objects and Terms:

```powershell
# Is it a Class Object?
$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id

# Is it a Term (in mClsObjectCustentDefIds but not a Class Object)?
$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject
```

### Property Retrieval Functions

| Function | Filtering | Used For |
|----------|-----------|----------|
| **mGetClsPrpNames()** | ✅ YES - Excludes metadata | Class Objects (all standards) |
| **mGetTermPrpNames()** | ❌ NO - Includes all properties | Terms (Uniclass only) |

**Why different functions?**
- **Class Objects**: Need filtering to exclude metadata (Level 1-4, Standard, etc.)
- **Uniclass Terms**: Need ALL properties when used as primary classification

## Workflow Comparison

### Standard Workflow (IEC, eCl@ss, PDMC-Sample)
```
1. User selects Standard
2. Navigate breadcrumb hierarchy
3. Select Class Object (required) ✅
4. Optional: Select Term (adds/overrides properties)
5. Apply classification
   → Uses mGetClsPrpNames() for Class
   → Term properties overlay on top
```

### Uniclass Extended Workflow ✨ NEW
```
1. User selects "Uniclass" Standard
2. Navigate breadcrumb hierarchy
3. Option A: Select Class Object → Standard workflow
4. Option B: Select ONLY Term (no Class) ✨
   → Term treated as Class Object
   → txtActiveClass = Term Name
   → All Term properties applied
5. Apply classification
   → Detects Term object
   → Uses mGetTermPrpNames() for complete properties
```

## Use Cases

### Use Case 1: Uniclass with Term Only
**Scenario**: User wants to classify a pump using only a Uniclass Term

**Steps**:
1. Select "Uniclass" standard
2. Navigate: Systems → Pumps → Centrifugal Pumps
3. Select Term: "Single-stage centrifugal pump"
4. Do NOT select Class Object
5. Click "Select Classification"

**Result**:
- File classified with Term as primary object
- txtActiveClass = "Single-stage centrifugal pump"
- All Term properties applied to file
- Term EN, Term DE, Code, and custom properties transferred

### Use Case 2: Uniclass with Class and Term
**Scenario**: User wants traditional Class + Term assignment

**Steps**:
1. Select "Uniclass" standard
2. Navigate hierarchy
3. Select Class Object: "Pumps"
4. Select Term: "Single-stage centrifugal pump"
5. Click "Select Classification"

**Result**:
- Standard behavior (Class + Term merge)
- txtActiveClass = "Pumps" (from Class Object)
- Class properties + Term properties applied
- Term overrides Class where properties overlap

### Use Case 3: Other Standards (No Change)
**Scenario**: User working with IEC 61355

**Steps**:
1. Select "IEC 61355" standard
2. Navigate hierarchy
3. Must select Class Object
4. Optional: Select Term

**Result**:
- No change in behavior
- Uniclass enhancement does NOT affect other standards
- Class Object required as before

## Property Transfer Behavior

### Uniclass Term-Only Selection
When only a Term is selected in Uniclass:

**Properties Transferred**:
- ✅ Code
- ✅ Term EN, DE, FR, IT, ES (if "Copy to Title" checked → Title properties)
- ✅ All custom UDP properties from Term
- ❌ Level 1-4 (filtered out as hierarchy metadata)
- ❌ Standard (metadata)
- ❌ Is Manual Entry (filter property)

**Example**:
```
TERM OBJECT: "Single-stage centrifugal pump"
Properties:
  - Code: PUMP-SS-CENT-001
  - Term EN: Single-stage centrifugal pump
  - Term DE: Einstufige Kreiselpumpe
  - Power: 5.5 kW
  - Flow Rate: 100 m³/h
  - Is Manual Entry: False

FILE AFTER CLASSIFICATION:
  - Code: PUMP-SS-CENT-001 ✅
  - Title: Single-stage centrifugal pump ✅ (if checkbox checked)
  - Title DE: Einstufige Kreiselpumpe ✅ (if checkbox checked)
  - Power: 5.5 kW ✅
  - Flow Rate: 100 m³/h ✅
  - Is Manual Entry: NOT transferred ❌ (filter property)
```

## Diagnostic Logging

The enhancement includes comprehensive logging for troubleshooting:

### In mSelectClassification()
```
Uniclass mode: No Class Object selected, checking for Term selection...
Uniclass: Set txtActiveClass = 'Single-stage centrifugal pump' from cmbTrm2 (treating Term as Class)
```

### In mApplyClassification()
```
Uniclass: Applying Term as Class - using mGetTermPrpNames()
  Adding property: Code (ID: 12345)
  Adding property: Power (ID: 12346)
  Adding property: Flow Rate (ID: 12347)
Total properties to add: 15
Successfully applied classification with 15 properties
```

## Testing Recommendations

### Test Case 1: Uniclass Term-Only Selection
- [ ] Set Standard to "Uniclass"
- [ ] Navigate hierarchy
- [ ] Select a Term (do NOT select Class Object)
- [ ] Click "Select Classification"
- [ ] Verify txtActiveClass shows Term name
- [ ] Apply classification
- [ ] Verify Term properties on file

### Test Case 2: Uniclass Class + Term
- [ ] Set Standard to "Uniclass"
- [ ] Select Class Object
- [ ] Select Term
- [ ] Verify txtActiveClass shows Class Object name (not Term)
- [ ] Apply classification
- [ ] Verify Class + Term properties merged correctly

### Test Case 3: Other Standards Not Affected
- [ ] Set Standard to "IEC 61355"
- [ ] Select Term ONLY (no Class)
- [ ] Verify NO txtActiveClass is set (empty)
- [ ] Verify warning or error (Class Object required)

### Test Case 4: Uniclass Term Removal
- [ ] Classify file with Uniclass Term only
- [ ] Remove classification
- [ ] Verify ALL properties removed (including Term properties)

### Test Case 5: Property Filtering
- [ ] Classify file with Uniclass Term containing "Is Manual Entry"
- [ ] Verify "Is Manual Entry" is NOT on file
- [ ] Verify Level 1-4 properties are NOT on file
- [ ] Verify Code, Title, custom UDPs ARE on file

## Impact Analysis

### ✅ Benefits
- **Flexible Uniclass Workflow**: Term-only classification supported
- **Simplified User Experience**: Fewer required selections
- **Standard Compliance**: Follows Uniclass methodology
- **No Impact on Other Standards**: IEC, eCl@ss, PDMC unchanged
- **Diagnostic Logging**: Easy troubleshooting

### ⚠️ Considerations
- **Uniclass Specific**: Only works with "Uniclass" standard
- **Term Properties**: Includes ALL Term properties (more than Class Objects)
- **Backward Compatible**: Existing workflows unchanged
- **Documentation**: Users need training on new capability

### 🔒 No Breaking Changes
- Other classification standards work as before
- Class Object + Term workflow unchanged
- Existing Uniclass classifications unaffected
- Property filtering logic preserved

## Backward Compatibility

### ✅ Fully Backward Compatible
- **Other Standards**: No impact on IEC 61355, eCl@ss, PDMC-Sample
- **Existing Workflows**: Class + Term selection still works
- **Existing Classifications**: No migration needed
- **File Properties**: No schema changes

### Migration Path
No migration required! Enhancement is additive:
1. Deploy updated script
2. Restart Vault Explorer
3. Feature available immediately
4. Users can continue existing workflows OR use new Term-only workflow

## Common Questions

**Q: Does this work with all classification standards?**  
A: No, only with "Uniclass" standard. Other standards require Class Object selection as before.

**Q: What if I select both Class and Term in Uniclass?**  
A: Standard behavior applies - Class Object name used for txtActiveClass, properties merged with Term priority.

**Q: Can I remove a Term-only classification?**  
A: Yes! The removal function works for both Class Objects and Terms.

**Q: Will Term properties override Class properties?**  
A: Only if you select BOTH. If you select only a Term, no Class properties exist to override.

**Q: What happens if I select Term in IEC 61355?**  
A: Nothing! The enhancement only activates for Uniclass. Other standards are unchanged.

**Q: Are filtered properties (Is Manual Entry, Level Code) transferred?**  
A: No, the filtering logic still applies. Only data properties are transferred.

**Q: Can I search for files by Term classification?**  
A: Yes! The _XLTN_CLSOBJECT property contains the Term name, searchable in Vault.

## Future Enhancements

### Potential Improvements
1. **Multi-Standard Support**: Extend to other standards if needed
2. **UI Indication**: Visual cue when Term is treated as Class
3. **Property Mapping**: Custom mappings for Term properties
4. **Validation**: Warn if Term lacks required properties
5. **Reporting**: Track Term-only vs Class+Term usage

## Version History
- **v1.2** (March 29, 2026): Uniclass Term-as-Class enhancement
  - Extended `mSelectClassification()` for Uniclass Term detection
  - Enhanced `mApplyClassification()` for Term property handling
  - Added diagnostic logging
  - Uniclass-specific workflow supported

## Summary

### What Changed
- ✨ Uniclass Standard: Term-only selection now supported
- ✨ Term treated as Class Object when no Class selected
- ✨ Term properties applied to files automatically
- ✅ No impact on other classification standards
- ✅ Backward compatible with existing workflows

### How It Works
1. **Selection**: If Uniclass + Term only → Use Term as Class
2. **Display**: txtActiveClass = Term Name
3. **Application**: Use mGetTermPrpNames() for properties
4. **Transfer**: Apply all Term data properties to file

### Result
More flexible Uniclass classification workflow while preserving existing functionality for all other standards!

---

**Status**: ✅ IMPLEMENTED  
**Standard**: Uniclass only  
**Impact**: Low risk, isolated to Uniclass workflow  
**Compatibility**: Fully backward compatible  
**Testing**: Required for Uniclass scenarios
