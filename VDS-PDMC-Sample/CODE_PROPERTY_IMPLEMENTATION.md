# "Code" Property Implementation for File Classification

## Overview
Enabled the "Code" property to be transferred from classification objects (Class Objects and Terms) to files when assigning classifications.

## Problem
Previously, the "Code" property was included in the exclusion list (`$Global:mClsPropNames`), which prevented it from being transferred to files during classification assignment. This exclusion list is designed to filter out properties that describe the classification hierarchy itself (like Level 1-4, Standard, etc.) rather than actual data properties.

## Solution
Removed "Code" (`$UIString["Adsk.QS.ClsCode"]`) from the `$Global:mClsPropNames` exclusion list in the `mInitializeClassificationTab` function.

## File Modified

### **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**

**Location**: Lines 40-45 in the `mInitializeClassificationTab` function

**BEFORE**:
```powershell
$Global:mClsPropNames = (
    $UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
    $UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
    $UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsCode"], $UIString["Adsk.QS.ClsLevelCode"], 
    $UIString["Comments"], $UIString["CommentsDE"] )
```

**AFTER**:
```powershell
$Global:mClsPropNames = (
    $UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
    $UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
    $UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsLevelCode"], 
    $UIString["Comments"], $UIString["CommentsDE"] )
```

**Change**: Removed `$UIString["Adsk.QS.ClsCode"]` from line 43

## Technical Details

### Understanding the Exclusion List
The `$Global:mClsPropNames` array serves as an **exclusion list** containing property names that should NOT be transferred to files. This list is used in three key locations:

1. **mGetClsPrpNames (Line 372)**: Filters out properties when retrieving class property names
   ```powershell
   If ($Global:mCustentUdpDefs | Where-Object { $_.Id -eq $mPropInst.PropDefId -and $mPropInst.PropDefId -notin $Global:mClsPropDefIds }) {
   ```

2. **mGetClsDfltValues (Line 259)**: Only adds properties that are NOT in the exclusion list
   ```powershell
   if ($Global:mActvClsPrpNames[$mClsProp.Key] -notin $Global:mClsPropNames) {
   ```

3. **mGetFileClsValues (Line 221)**: Filters out classification level names for display
   ```powersharp
   if ($mClsProp.Value -notin $Global:mClsLevelNames) {
   ```

### Properties Currently Excluded from Transfer
After this change, the following properties remain in the exclusion list and will NOT be transferred to files:

| Property Display Name | UIString ID | Purpose |
|----------------------|-------------|---------|
| Segment (Level 1) | Adsk.QS.ClsLevel_01 | Classification hierarchy level |
| Main Group (Level 2) | Adsk.QS.ClsLevel_02 | Classification hierarchy level |
| Group (Level 3) | Adsk.QS.ClsLevel_03 | Classification hierarchy level |
| Sub Group (Level 4) | Adsk.QS.ClsLevel_04 | Classification hierarchy level |
| Class | Adsk.QS.ClsObject | Classification object type |
| Standard | Adsk.QS.ClsStandard | Classification standard (IEC, eCl@ss, etc.) |
| Term DE | ClassTerms_09 | German term (hierarchy metadata) |
| Term EN | ClassTerms_10 | English term (hierarchy metadata) |
| Term FR | ClassTerms_11 | French term (hierarchy metadata) |
| Term IT | ClassTerms_12 | Italian term (hierarchy metadata) |
| Term ES | ClassTerms_12a | Spanish term (hierarchy metadata) |
| Level Code | Adsk.QS.ClsLevelCode | Classification level code |
| Comments | Comments | General comments |
| CommentsDE | CommentsDE | German comments |

**Note**: The Term language properties (DE, EN, FR, IT, ES) in this exclusion list refer to Term object names in the hierarchy, not the actual Term data properties that get transferred when using the "Copy Term → Title" feature.

### Properties Now Included for Transfer

| Property Display Name | UIString ID | Purpose |
|----------------------|-------------|---------|
| **Code** | **Adsk.QS.ClsCode** | Classification code/identifier |

Plus any other custom UDP properties defined on Class Objects or Terms that are not in the exclusion list.

## Impact

### Before Change
- When assigning a classification to a file, the "Code" property from the Class Object or Term would NOT appear in the property grid
- The "Code" property would NOT be added to the file's properties
- Users would need to manually add the Code property to files

### After Change
- When assigning a classification to a file, the "Code" property from the Class Object or Term WILL appear in the property grid (both in preview and edit mode)
- The "Code" property WILL be automatically added to the file's properties when classification is applied
- The "Code" value is preserved when using either Class Objects or Terms

## Workflow Example

1. **Create Classification Object**:
   - Admin creates a Class Object with properties including "Code" = "PUMP-001"

2. **Assign Classification to File**:
   - User opens a file in Vault and navigates to the Classification tab
   - User clicks "Select Classification" button
   - User selects the classification through the breadcrumb navigation and tree view
   - The property grid displays all properties INCLUDING "Code" with value "PUMP-001"
   - User clicks "Select Classification" to apply

3. **Result**:
   - File now has "Code" property set to "PUMP-001"
   - All other classification properties are also transferred (except those in exclusion list)

## Testing Recommendations

1. **Test with Class Object**:
   - Create a Class Object with "Code" property populated
   - Assign to a file
   - Verify "Code" appears in the classification property grid
   - Verify "Code" is written to file properties

2. **Test with Term Object**:
   - Create a Term Object with "Code" property populated
   - Assign to a file
   - Verify "Code" appears in the term property grid
   - Verify "Code" is written to file properties

3. **Test Combined (Class + Term)**:
   - Assign both a Class Object (with Code="CLS-001") and Term Object (with Code="TRM-002")
   - Verify that Term's Code value takes precedence (Term has priority in merge logic)

4. **Test Edit Mode**:
   - Open a file that already has classification assigned
   - Verify "Code" displays in the Classification tab property grid
   - Verify "Code" can be edited through the file properties dialog

## Related Functions

- `mInitializeClassificationTab()` - Initializes exclusion list
- `mGetClsPrpNames()` - Retrieves class property names (filters using exclusion list)
- `mGetClsDfltValues()` - Gets class default values (filters using exclusion list)
- `mGetTermDfltValues()` - Gets term default values (filters using exclusion list)
- `mSelectClassification()` - Merges Class and Term properties for transfer to file
- `mApplyClassification()` - Applies classification properties to file

## Notes

- The "Level Code" property (`Adsk.QS.ClsLevelCode`) remains in the exclusion list and will NOT be transferred
- If both Class Object and Term Object have "Code" properties, the Term's Code value will be used (Term has priority in merge logic)
- The "Code" property must be defined as a UDP (User-Defined Property) on both File entities and Custom Object entities in Vault
