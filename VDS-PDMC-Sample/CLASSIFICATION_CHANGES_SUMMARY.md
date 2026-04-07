# Classification System Changes Summary
**Date**: March 29, 2026  
**System**: Autodesk Vault Data Standard 2026 - Classification Extension

---

## Change 1: Added Spanish Language Support (Term ES)

### Overview
Added support for Spanish language terms and titles throughout the classification system.

### Files Modified
1. **en-US\UIStrings.xml** - Added `ClassTerms_12a` → "Term ES"
2. **en-US\PropertyTranslations.xml** - Added TERM-ES and TITLE-ES translations
3. **de-DE\UIStrings.xml** - Added `ClassTerms_12a` → "Begriff ES"
4. **de-DE\PropertyTranslations.xml** - Added TERM-ES and TITLE-ES translations
5. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**:
   - Added `ClassTerms_12a` to `$Global:mClsPropNames` array
   - Added Term ES → Title ES mapping in `mSelectClassification()`

### Impact
- Users can now define Spanish terms in Term custom objects
- When "Copy Term → Title" checkbox is checked, Term ES values automatically transfer to Title ES on files
- Full language support now includes: DE, EN, FR, IT, **ES**

### Property Mappings (when checkbox checked)
- Term DE → Title DE
- Term EN → Title
- Term FR → Title FR
- Term IT → Title IT
- **Term ES → Title ES** ✨ NEW

---

## Change 2: Enabled "Code" Property Transfer to Files

### Overview
Removed "Code" property from the exclusion list to allow it to be transferred from classification objects to files.

### Files Modified
1. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**:
   - Removed `$UIString["Adsk.QS.ClsCode"]` from `$Global:mClsPropNames` exclusion list (Line 43)

### Technical Details
**BEFORE** (Line 43):
```powershell
$UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsCode"], $UIString["Adsk.QS.ClsLevelCode"],
```

**AFTER** (Line 43):
```powershell
$UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsLevelCode"],
```

### Impact
**Before**: 
- "Code" property was excluded and NOT transferred to files during classification assignment
- Users had to manually add Code values to files

**After**:
- "Code" property is now included in the classification property grid (preview and edit modes)
- "Code" property is automatically transferred to files when classification is assigned
- Code values from both Class Objects and Terms are supported (Term takes priority if both exist)

### Workflow Example
1. Create a Class Object or Term with Code = "PUMP-001"
2. Assign classification to a file
3. Code property automatically appears in the property grid with value "PUMP-001"
4. Code is written to the file's properties when classification is applied

---

## Change 3: Added "Is Manual Entry" Filter Property ✨ NEW

### Overview
Implemented "Is Manual Entry" as a classification-level filter property for Term objects. This property is used for filtering and classification management and is NOT transferred to files.

### Files Modified
1. **en-US\UIStrings.xml** - Added `ClassTerms_12b` → "Is Manual Entry"
2. **en-US\PropertyTranslations.xml** - Added IS-MANUAL-ENTRY translation
3. **de-DE\UIStrings.xml** - Added `ClassTerms_12b` → "Ist manuelle Eingabe"
4. **de-DE\PropertyTranslations.xml** - Added IS-MANUAL-ENTRY translation
5. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**:
   - Added `ClassTerms_12b` to `$Global:mClsPropNames` exclusion list (Line 43)

### Technical Details
**Change** (Line 43):
```powershell
$UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["ClassTerms_12b"], $UIString["Adsk.QS.ClsLevelCode"],
```

### Impact
**Purpose**: 
- Filter/flag on Term objects to indicate manual entry requirement
- Used for organizing and searching Term catalogs
- Visible in classification dialog but NOT transferred to files

**Use Cases**:
- Filter Terms by entry type (manual vs. automatic)
- Search for Terms requiring manual data entry
- Organize classification workflows based on entry requirements
- Create reports grouped by entry type

**Behavior**:
- ✅ Property appears in Term properties grid (for viewing)
- ❌ Property is NOT transferred to files during classification
- ✅ Can be used in Vault searches and filters
- ✅ Helps administrators organize Term catalogs

---

## Change 4: Fixed Classification Removal Issue 🔧 CRITICAL FIX

### Overview
Fixed a critical bug where "Class" property and other metadata properties were not being removed when removing classification from files.

### Root Cause
The `mRemoveClassification()` function was using `mGetClsPrpNames()` which filters out properties in the exclusion list. This meant metadata properties like "Class", "Standard", "Is Manual Entry", etc. were never retrieved and therefore never removed.

### Files Modified
1. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**:
   - Added `mGetAllClsPrpNames()` function (after Line 377)
   - Updated `mRemoveClassification()` function (around Line 634)

### Technical Details

**NEW Function Added**:
```powershell
function mGetAllClsPrpNames($ClassId) { 
    # Retrieves ALL properties without filtering - used for removal
    # NO exclusion check - returns everything
}
```

**Updated Function**:
```powershell
# BEFORE:
$mActvClsPrpNames = mGetClsPrpNames($mActiveClass[0].Id)  # Filtered

# AFTER:
$mActvClsPrpNames = mGetAllClsPrpNames($mActiveClass[0].Id)  # Unfiltered
```

### Impact

**Before Fix**: ❌
- "Class" property remained after removal
- "Standard", "Is Manual Entry", and other metadata remained
- Incomplete classification cleanup
- Manual intervention required
- User confusion about removal status

**After Fix**: ✅
- ALL classification properties removed completely
- Clean slate after removal
- No leftover metadata
- Diagnostic logging added for troubleshooting
- Predictable and complete removal

### Properties Now Properly Removed
When removing classification, the following are now ALL removed:
- **Class** ✨ NOW FIXED
- Standard
- Is Manual Entry
- Level Code
- Term DE, EN, FR, IT, ES (hierarchy names)
- Level 1-4 (Segment, Main Group, Group, Sub Group)
- Comments, CommentsDE
- Code, Title, and all custom UDPs

### Why This Fix Was Needed
- **Apply Classification**: Uses filtered properties (correct - only add data)
- **Remove Classification**: Needs ALL properties (was broken - now fixed)

---

## Change 5: Uniclass Term-as-Class Enhancement ✨ NEW WORKFLOW

### Overview
Extended the classification assignment workflow for **Uniclass Standard** to support selecting only a Term (without a Class Object) and treating it as the primary classification object.

### Business Need
Uniclass users often want to classify objects using only Terms without requiring Class Object selection, providing a more flexible and streamlined workflow.

### Files Modified
1. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**:
   - Updated `mSelectClassification()` function (Lines 487-518)
   - Updated `mApplyClassification()` function (Lines 622-663)

### Technical Details

**Enhanced Selection Logic**:
```powershell
# If no Class Object selected AND Standard is Uniclass
# Check for Term selection and use it as Class Object
if (-not $selectedClassObject -and $global:mActiveStandard -eq "Uniclass") {
    # Search cmbTrm1-4 for selected Term
    # Set txtActiveClass = Term Name
}
```

**Enhanced Application Logic**:
```powershell
# Detect object type: Class Object or Term
$isClassObject = $mActiveClass[0].CustEntDefId -eq $Global:mClassCustentDef.Id
$isTerm = $mActiveClass[0].CustEntDefId -in $Global:mClsObjectCustentDefIds -and -not $isClassObject

# For Uniclass Terms: Use mGetTermPrpNames() (all properties)
# For Class Objects: Use mGetClsPrpNames() (filtered properties)
```

### Impact

**New Uniclass Workflow**: ✨
1. Select "Uniclass" standard
2. Navigate hierarchy
3. **Option A**: Select Class Object (traditional)
4. **Option B**: Select ONLY Term (new capability)
   - Term treated as Class Object
   - All Term properties applied to file
   - txtActiveClass = Term Name

**Other Standards**: ✅
- No impact on IEC 61355, eCl@ss, PDMC-Sample
- Class Object still required
- Behavior unchanged

**Use Case Example**:
```
Uniclass: Select Term "Single-stage centrifugal pump" (no Class)
↓
txtActiveClass = "Single-stage centrifugal pump"
↓
Apply: Code, Title, Power, Flow Rate, etc.
↓
File classified with Term as primary object
```

### Benefits
- ✅ More flexible Uniclass classification
- ✅ Simplified workflow (fewer required selections)
- ✅ Standard-specific (only affects Uniclass)
- ✅ Backward compatible (existing workflows unchanged)
- ✅ No impact on other standards

---

## Properties Transfer Behavior

### Properties EXCLUDED from File Transfer (Metadata/Hierarchy)
These properties describe the classification structure itself and are NOT transferred:
- Segment (Level 1)
- Main Group (Level 2)
- Group (Level 3)
- Sub Group (Level 4)
- Class
- Standard (IEC 61355, eCl@ss, etc.)
- Term DE, EN, FR, IT, ES (hierarchy names)
- **Is Manual Entry** ✨ NEW (filter/flag property)
- Level Code
- Comments
- CommentsDE

### Properties INCLUDED for File Transfer (Data Properties)
These properties contain actual classification data and ARE transferred:
- **Code** ✨ NOW INCLUDED
- Title DE, EN, FR, IT, ES (when "Copy Term → Title" is checked)
- Any other custom UDP properties not in the exclusion list

---

## Testing Checklist

### Test Term ES Support
- [ ] Create/Edit a Term object with Term ES populated
- [ ] Assign Term to file with "Copy Term → Title" checked
- [ ] Verify Term ES value appears in property grid
- [ ] Verify Title ES is populated on the file

### Test Code Property Transfer
- [ ] Create Class Object with Code property (e.g., "CLS-001")
- [ ] Assign to file - verify Code appears in property grid
- [ ] Verify Code is written to file properties
- [ ] Create Term Object with Code property (e.g., "TRM-002")
- [ ] Assign to file - verify Code appears in term property grid
- [ ] Test combined assignment (both Class + Term) - verify Term's Code takes priority

### Test "Is Manual Entry" Filter Property ✨ NEW
- [ ] Create/Edit a Term object with "Is Manual Entry" = True
- [ ] Open "Select Classification" dialog and select the Term
- [ ] Verify "Is Manual Entry" appears in Term properties grid
- [ ] Assign Term to file
- [ ] Verify "Is Manual Entry" is NOT written to file properties
- [ ] Search for Terms where "Is Manual Entry" = True
- [ ] Verify correct Terms are returned in search

### Test Combined Changes
- [ ] Create Term with Code, Term ES, and "Is Manual Entry" populated
- [ ] Assign to file with checkbox checked
- [ ] Verify Code and Title ES ARE written to file
- [ ] Verify "Is Manual Entry" is NOT written to file

---

## Administrator Actions Required

### 1. Property Definitions Setup
Ensure the following property definitions exist in Vault:

**For Custom Objects (Terms and Class Objects)**:
- Property Name: "Term ES" (Type: Text)
- Property Name: "Code" (Type: Text)
- Property Name: "Is Manual Entry" (Type: Boolean or Text) ✨ NEW

**For Files**:
- Property Name: "Title ES" (Type: Text)
- Property Name: "Code" (Type: Text)
- NOTE: "Is Manual Entry" is NOT needed on files (not transferred)

### 2. Update Existing Data
- Review existing Term objects and add Spanish translations where needed
- Review existing Class Objects and Terms to populate Code values
- Add "Is Manual Entry" flag to Term objects as appropriate (True/False)
- Consider running a bulk update to populate properties on existing classifications

### 3. User Training
- Inform users about new Term ES capability
- Demonstrate how Code property is now automatically transferred
- Explain "Is Manual Entry" flag usage for filtering Terms
- Update any user documentation or workflows

---

## Related Documentation
- See **TERM_ES_IMPLEMENTATION_SUMMARY.md** for detailed Term ES implementation
- See **CODE_PROPERTY_IMPLEMENTATION.md** for detailed Code property implementation
- See **IS_MANUAL_ENTRY_IMPLEMENTATION.md** for detailed "Is Manual Entry" implementation
- See **CLASSIFICATION_REMOVAL_FIX.md** for classification removal fix details
- See **UNICLASS_TERM_AS_CLASS_ENHANCEMENT.md** for Uniclass Term-as-Class workflow
- See **UNICLASS_TERM_REMOVAL_FIX.md** for Uniclass Term-as-Class removal fix
- See **CLASSIFICATION_PROPERTY_FLOW.md** for visual flow diagrams and technical details
- See **copilot-instructions.md** for overall system architecture

---

## Version History
- **v1.2.1** (March 29, 2026):
  - **FIX**: Uniclass Term-as-Class removal issue
    - Updated `mRemoveClassification()` to detect Term vs Class Object
    - For Terms: Use `mGetTermPrpNames()` for complete property removal
    - For Class Objects: Use `mGetAllClsPrpNames()` (unchanged)
    - Ensures complete removal of Uniclass Term-as-Class properties
- **v1.2** (March 29, 2026):
  - **UNICLASS ENHANCEMENT**: Term-as-Class workflow ✨
    - Extended `mSelectClassification()` to detect Term selection when no Class Object selected
    - Enhanced `mApplyClassification()` to handle Terms as primary classification objects
    - Added object type detection (Class vs Term)
    - Uniclass-specific: Allows Term-only classification assignment
    - No impact on other classification standards
- **v1.1** (March 29, 2026): 
  - **CRITICAL FIX**: Classification removal issue
    - Added `mGetAllClsPrpNames()` function to retrieve all properties without filtering
    - Fixed `mRemoveClassification()` to properly remove "Class" and all metadata properties
    - Added diagnostic logging for troubleshooting
- **v1.0** (March 29, 2026): Initial implementation
  - Added Term ES support (5 languages now supported)
  - Enabled Code property transfer to files
  - Added "Is Manual Entry" filter property for Term organization

## Support Notes
- All changes are backward compatible
- No changes required to existing classification data structures
- Existing classifications continue to work without modification
- New properties (Term ES, Code on files, Is Manual Entry) are optional and populated as needed
- "Is Manual Entry" is a filter property only - not transferred to files
