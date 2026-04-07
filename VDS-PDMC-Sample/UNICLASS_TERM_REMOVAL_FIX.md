# Uniclass Term-as-Class Removal Fix

## Issue
When a Uniclass Term was assigned as a Class Object (Term-as-Class workflow), the removal function was not properly handling this case. It was using `mGetAllClsPrpNames()` which is designed for Class Objects, but Terms require `mGetTermPrpNames()` to retrieve all their properties.

## Root Cause
The `mRemoveClassification()` function was treating all classification objects as Class Objects and using `mGetAllClsPrpNames()` to retrieve properties. However, when a Uniclass Term is used as a Class (Term-as-Class), the object is actually a Term entity, not a Class Object entity, so different property retrieval is needed.

## Solution
Updated `mRemoveClassification()` to detect the object type (Class Object vs Term) and use the appropriate function:
- **Class Objects**: Use `mGetAllClsPrpNames()` (retrieves all Class Object properties)
- **Terms**: Use `mGetTermPrpNames()` (retrieves all Term properties)

## File Modified

### **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**
**Location**: `mRemoveClassification()` function (around Line 670)

**BEFORE**:
```powershell
#get class object to remove - use mGetAllClsPrpNames to get ALL properties
$mActiveClass = mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value)
$mActvClsPrpNames = mGetAllClsPrpNames($mActiveClass[0].Id)
```

**AFTER**:
```powershell
#get class object to remove
$mActiveClass = mGetCustentiesByName($Prop["_XLTN_CLSOBJECT"].Value)

# Check if the selected object is a Class Object or Term
$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id
$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject

# Determine which function to use based on object type
if ($isTerm) {
    # For Terms (Uniclass Term-as-Class), use mGetTermPrpNames to get ALL properties
    $dsDiag.Trace("Removing Uniclass Term-as-Class - using mGetTermPrpNames()")
    $mActvClsPrpNames = mGetTermPrpNames($mActiveClass[0].Id)
}
else {
    # For Class Objects, use mGetAllClsPrpNames to get ALL properties
    $dsDiag.Trace("Removing Class Object - using mGetAllClsPrpNames()")
    $mActvClsPrpNames = mGetAllClsPrpNames($mActiveClass[0].Id)
}
```

## Technical Details

### Object Type Detection
The same logic used in `mApplyClassification()` is now used in `mRemoveClassification()`:

```powershell
# Is it a Class Object?
$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id

# Is it a Term (in mClsObjectCustentDefIds but not a Class Object)?
$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject
```

### Function Selection for Removal

| Object Type | Function Used | Properties Retrieved |
|-------------|---------------|----------------------|
| **Class Object** | mGetAllClsPrpNames() | All Class Object properties (including "Class") |
| **Term** | mGetTermPrpNames() | All Term properties |

### Why Different Functions?
- **Class Objects**: Have properties like "Class" that need special handling
- **Terms**: Already include all properties without special filtering
- Both retrieve ALL properties (no exclusions) for complete removal

## Impact

### Before Fix ❌
When removing a Uniclass Term-as-Class:
- Used `mGetAllClsPrpNames()` on a Term object
- May have missed Term-specific properties
- Incomplete removal
- Properties could remain on file

### After Fix ✅
When removing a Uniclass Term-as-Class:
- Detects object type correctly
- Uses `mGetTermPrpNames()` for Terms
- Complete property retrieval
- All properties removed cleanly

## Workflow Examples

### Scenario 1: Remove Uniclass Term-as-Class
```
File classified with: Uniclass Term "Single-stage centrifugal pump" (no Class Object)

Remove Classification:
  ↓
Detection: Object is Term (CustEntDefId check)
  ↓
Function: mGetTermPrpNames() used
  ↓
Properties: Code, Power, Flow Rate, Term EN/DE/ES, etc.
  ↓
Result: ALL Term properties removed ✅
```

### Scenario 2: Remove Traditional Class Object
```
File classified with: IEC Class Object "Pumps"

Remove Classification:
  ↓
Detection: Object is Class Object (CustEntDefId check)
  ↓
Function: mGetAllClsPrpNames() used
  ↓
Properties: Class, Code, Material, Weight, etc.
  ↓
Result: ALL Class properties removed ✅
```

### Scenario 3: Remove Class + Term (Traditional)
```
File classified with: Class Object "Pumps" + Term "Centrifugal"

Remove Classification:
  ↓
Detection: txtActiveClass = "Pumps" (Class Object name)
  ↓
Function: mGetAllClsPrpNames() used (Class takes precedence)
  ↓
Properties: Class properties + overlaid Term properties
  ↓
Result: ALL classification properties removed ✅
```

## Diagnostic Logging

Enhanced logging helps identify which path is taken:

### For Term Removal (Uniclass Term-as-Class)
```
...remove class - file found
Removing Uniclass Term-as-Class - using mGetTermPrpNames()
  Removing property: Code (ID: 12345)
  Removing property: Power (ID: 12346)
  Removing property: Term EN (ID: 12347)
  ...
Total properties to remove: 18
Successfully removed 18 classification properties
```

### For Class Object Removal
```
...remove class - file found
Removing Class Object - using mGetAllClsPrpNames()
  Removing property: Class (ID: 12340)
  Removing property: Code (ID: 12345)
  Removing property: Material (ID: 12348)
  ...
Total properties to remove: 15
Successfully removed 15 classification properties
```

## Consistency with Apply Logic

The removal logic now mirrors the apply logic for symmetry:

| Operation | Class Object | Uniclass Term-as-Class |
|-----------|--------------|------------------------|
| **Apply** | mGetClsPrpNames() | mGetTermPrpNames() |
| **Remove** | mGetAllClsPrpNames() | mGetTermPrpNames() ✅ FIXED |

**Note**: Apply uses filtered functions, Remove uses unfiltered functions (to get ALL properties including metadata).

## Testing Recommendations

### Test Case 1: Uniclass Term-as-Class Removal ✨ KEY TEST
- [ ] Classify file with Uniclass Term only (no Class Object)
- [ ] Verify properties: Code, Title, Power, etc. on file
- [ ] Remove classification
- [ ] Verify ALL properties removed (none remaining)
- [ ] Check diagnostic log for "Removing Uniclass Term-as-Class" message

### Test Case 2: Class Object Removal
- [ ] Classify file with Class Object (any standard)
- [ ] Remove classification
- [ ] Verify ALL properties removed including "Class"
- [ ] Check diagnostic log for "Removing Class Object" message

### Test Case 3: Traditional Class + Term Removal
- [ ] Classify file with Class Object + Term
- [ ] Remove classification
- [ ] Verify ALL properties removed
- [ ] Verify no Term-specific properties remain

### Test Case 4: Property Count Validation
- [ ] Before removal: Count properties on file
- [ ] Remove classification
- [ ] Check diagnostic log: "Total properties to remove: X"
- [ ] Verify count matches actual properties removed

## Backward Compatibility

### ✅ No Breaking Changes
- Class Object removal works as before
- Traditional Class + Term removal unchanged
- Only adds Term detection for Uniclass Term-as-Class scenario
- Diagnostic logging enhanced

### ✅ Symmetric with Apply
- Apply detects Class vs Term → Uses appropriate function
- Remove detects Class vs Term → Uses appropriate function
- Consistent logic across operations

## Related Changes

This fix complements the Uniclass Term-as-Class enhancement:

1. **Change 5** (Original): Uniclass Term-as-Class assignment
   - `mSelectClassification()`: Detect Term selection
   - `mApplyClassification()`: Apply Term properties

2. **This Fix**: Uniclass Term-as-Class removal
   - `mRemoveClassification()`: Detect Term object
   - Use correct function for complete removal

## Version History
- **v1.2.1** (March 29, 2026): Uniclass Term-as-Class removal fix
  - Updated `mRemoveClassification()` to detect Term vs Class Object
  - For Terms: Use `mGetTermPrpNames()` for property retrieval
  - For Class Objects: Use `mGetAllClsPrpNames()` for property retrieval
  - Added diagnostic logging for object type detection
  - Complete and symmetrical handling of Uniclass Term-as-Class workflow

## Summary

### The Issue
Removing a Uniclass Term-as-Class classification was not using the correct property retrieval function, potentially leaving properties on files.

### The Solution
Added object type detection (Class vs Term) to `mRemoveClassification()` and use the appropriate function:
- Terms → `mGetTermPrpNames()`
- Class Objects → `mGetAllClsPrpNames()`

### The Result
Complete, clean removal of all classification properties for both Class Objects and Uniclass Term-as-Class scenarios.

---

**Status**: ✅ FIXED  
**Scope**: Uniclass Term-as-Class removal  
**Impact**: Critical for proper Uniclass Term-as-Class workflow  
**Risk**: Low (symmetric with apply logic)  
**Testing**: Required for Uniclass Term-as-Class scenarios
