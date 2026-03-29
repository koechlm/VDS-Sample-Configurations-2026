# Uniclass Classification - Explicit "Class" Property Removal Fix

## Version
**Version:** 1.2.2  
**Date:** 2025-01-XX### Property Translation Reference

### CLSOBJECT Property Definition

**Important Distinction:**

| Context | Internal Name | Display Name Source | EN Display Name | DE Display Name |
|---------|--------------|---------------------|-----------------|-----------------|
| **FILE Property** | CLSOBJECT | `$UIString["Adsk.QS.Classification_00"]` | **Class** | **Klasse** |
| **Custom Entity** | N/A | `$UIString["Adsk.QS.ClsObject"]` | **Class Object** | **Class Object** |

**Why the Difference Matters:**
- The "Class" property on a FILE has DispName = "Class" (from UIString `Adsk.QS.Classification_00`)
- The "Class Object" custom entity has DispName = "Class Object" (from UIString `Adsk.QS.ClsObject`)
- **FILE property lookup must use `$UIString["Adsk.QS.Classification_00"]`, NOT `Adsk.QS.ClsObject`**

**Source Files:**
- `en-US/UIStrings.xml`: 
  - `<UIString ID="Adsk.QS.Classification_00">Class</UIString>` ← Used for FILE property
  - `<UIString ID="Adsk.QS.ClsObject">Class Object</UIString>` ← Used for Custom Entity
- `de-DE/UIStrings.xml`:
  - `<UIString ID="Adsk.QS.Classification_00">Klasse</UIString>` ← Used for FILE property
  - `<UIString ID="Adsk.QS.ClsObject">Class Object</UIString>` ← Used for Custom Entity
- `en-US/PropertyTranslations.xml`: `<PropertyTranslation Name="CLSOBJECT">Class</PropertyTranslation>`
- `de-DE/PropertyTranslations.xml`: `<PropertyTranslation Name="CLSOBJECT">Klasse</PropertyTranslation>`:** Uniclass Term-as-Class removal incomplete - "Class" property left on files  
**Status:** ✅ COMPLETE

---

## Problem Statement

### User Report
> "The method to remove classification needs to remove the CLSOBJECT property in any case. If the standard and code matches a class object, remove all the properties given by this class. If the standard and code matches a term object, we remove all properties given by the term object. The CLSOBJECT must be removed in any case."

### Technical Issue
When any classification (Class Object or Term) is assigned to a file:

1. **Assignment Phase:**
   - Properties from the Class/Term object are copied to the file
   - A special "Class" property (internal name: `CLSOBJECT`) is added to the FILE entity
   - This property stores the name of the assigned Class/Term (via `$Prop["_XLTN_CLSOBJECT"].Value`)

2. **Removal Phase (BUG):**
   - Properties from the Class/Term object are removed from the file ✅
   - **BUT:** The "Class" property (`CLSOBJECT`) is NOT removed ❌
   - **Result:** File retains a "ghost" classification reference

### Root Cause
The `mRemoveClassification()` function removes properties that originated FROM the class/term object (custom entity properties), but does not explicitly remove the "Class" property definition that exists on the FILE entity itself.

**Key Distinction:**
- **Custom Entity Properties:** Properties stored on the Class/Term object (Code, Title, Description, etc.) - These are removed by `mGetAllClsPrpNames()` or `mGetTermPrpNames()`
- **FILE Property:** The "Class" property (CLSOBJECT) exists on the FILE entity, not on the Custom Entity - This must be explicitly removed by looking it up in FILE property definitions

---

## Solution Implementation

### Code Changes - `ADSK.TS.FileClassification.ps1`

#### Function Modified: `mRemoveClassification()`
**Location:** Lines 671-738

**Change:**
Added explicit lookup and removal of the "Class" property (CLSOBJECT) from FILE property definitions, independent of class/term object properties. This applies to ALL classification removals (Class Objects and Terms, all standards).

**Critical Discovery:**
The "Class" property on FILE entities uses a different display name than the "Class Object" custom entity:
- **FILE Property DispName:** Uses `$UIString["Adsk.QS.Classification_00"]` = "Class" (EN) / "Klasse" (DE)
- **Custom Entity:** Uses `$UIString["Adsk.QS.ClsObject"]` = "Class Object"
- **Internal Name (SysName):** CLSOBJECT (but not used for FILE property lookup)

```powershell
# EXPLICIT REMOVAL OF "Class" PROPERTY (CLSOBJECT)
# The "Class" property is added to the FILE to store the assigned class/term name.
# This property must ALWAYS be explicitly removed from the file, regardless of Class Object or Term.
# We need to: 1) Add CLSOBJECT to removal list, 2) Clear the _XLTN_CLSOBJECT value
try {
    $mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
    # Use DispName lookup with UIString for language-aware matching
    $mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
    
    if ($mClassPropertyDef) {
        # Only add if not already in the removal list
        if ($mPropsRemove -notcontains $mClassPropertyDef.Id) {
            $mPropsRemove += $mClassPropertyDef.Id
            $dsDiag.Trace("  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: $($mClassPropertyDef.Id), Display Name: $($mClassPropertyDef.DispName)")
        }
        else {
            $dsDiag.Trace("  [INFO] 'Class' property (CLSOBJECT) already in removal list - ID: $($mClassPropertyDef.Id)")
        }
        
        # Clear the _XLTN_CLSOBJECT value to ensure it gets unclassified
        # This is critical even if the property relates to file category and doesn't get removed
        $Prop["_XLTN_CLSOBJECT"].Value = ""
        $dsDiag.Trace("  [EXPLICIT] Cleared _XLTN_CLSOBJECT value")
    }
    else {
        $dsDiag.Trace("  [WARNING] 'Class' property not found in FILE property definitions")
    }
}
catch {
    $dsDiag.Trace("  [ERROR] Failed to find/add Class property for removal: $($_.Exception.Message)")
}
```

### Logic Flow

**Before Fix:**
```
Remove Classification
  ↓
Get Class/Term Properties (mGetAllClsPrpNames or mGetTermPrpNames)
  ↓
Add Property IDs to $mPropsRemove
  ↓
Call UpdateFilePropertyDefinitions([], $mPropsRemove, ...)
  ↓
RESULT: Class/Term properties removed, "Class" property REMAINS ❌
```

**After Fix:**
```
Remove Classification
  ↓
Get Class/Term Properties (mGetAllClsPrpNames or mGetTermPrpNames)
  ↓
Add Property IDs to $mPropsRemove (from Custom Entity)
  ↓
[NEW] Get FILE Property Definitions
  ↓
[NEW] Find "CLSOBJECT" property by SysName
  ↓
[NEW] Add CLSOBJECT.Id to $mPropsRemove (if not already present)
  ↓
Call UpdateFilePropertyDefinitions([], $mPropsRemove, ...)
  ↓
RESULT: Class/Term properties AND "Class" property removed ✅
```

---

## Property Translation Reference

### CLSOBJECT Property Definition
| Language | Internal Name | Display Name | Context |
|----------|--------------|--------------|---------|
| English  | `CLSOBJECT`  | `Class`      | FILE property |
| German   | `CLSOBJECT`  | `Klasse`     | FILE property |

**Source Files:**
- `en-US/PropertyTranslations.xml`: `<PropertyTranslation Name="CLSOBJECT">Class</PropertyTranslation>`
- `de-DE/PropertyTranslations.xml`: `<PropertyTranslation Name="CLSOBJECT">Klasse</PropertyTranslation>`

---

## Testing Verification

### Testing Verification

### Test Scenario 1: Class Object Removal (All Standards)
1. **Setup:**
   - Create a test file in Vault
   - Configure any standard (IEC 61355, eCl@ss, PDMC-Sample, or Uniclass) with Class Objects

2. **Assign Class Object:**
   - Edit file properties
   - Go to Classification tab
   - Select standard
   - Navigate to Class Object and apply

3. **Verify Assignment:**
   - Check file properties - should see:
     - ✅ Class Object properties (Code, Title, Description, etc.)
     - ✅ "Class" property = Class Object name

4. **Remove Classification:**
   - Edit file properties
   - Go to Classification tab
   - Click "Remove"
   - Confirm removal

5. **Verify Removal:**
   - Check file properties - should see:
     - ✅ Class Object properties REMOVED (Code, Title, Description gone)
     - ✅ **"Class" property REMOVED** ← Key fix verification

### Test Scenario 2: Uniclass Term-as-Class Removal
1. **Setup:**
   - Create a test file in Vault
   - Configure Uniclass standard with at least one Term (e.g., "Foundation Works")

2. **Assign Term:**
   - Edit file properties
   - Go to Classification tab
   - Select Uniclass standard
   - Navigate to Term: `Engineering > Substructure > Foundation Works`
   - Apply classification

3. **Verify Assignment:**
   - Check file properties - should see:
     - ✅ Term properties (Code, Title, Description, etc.)
     - ✅ "Class" property = "Foundation Works"
   - Check `$Prop["_XLTN_CLSOBJECT"].Value` = "Foundation Works"

4. **Remove Classification:**
   - Edit file properties
   - Go to Classification tab
   - Click "Remove"
   - Confirm removal

5. **Verify Removal:**
   - Check file properties - should see:
     - ✅ Term properties REMOVED (Code, Title, Description gone)
     - ✅ **"Class" property REMOVED** ← Key fix verification
   - Check `$Prop["_XLTN_CLSOBJECT"].Value` = empty

### Diagnostic Traces
Look for these trace messages in the log:

**For Class Object Removal:**
```
Removing Class Object - using mGetAllClsPrpNames()
  Removing property: Code (ID: 123)
  Removing property: Title (ID: 124)
  ...
  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: 999, Display Name: Class
Total properties to remove: 15
Successfully removed 15 classification properties
```

**For Term Removal:**
```
Removing Uniclass Term-as-Class - using mGetTermPrpNames()
  Removing property: Code (ID: 123)
  Removing property: Title (ID: 124)
  ...
  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: 999, Display Name: Class
Total properties to remove: 15
Successfully removed 15 classification properties
```

**If CLSOBJECT already in list (edge case):**
```
  [INFO] 'Class' property (CLSOBJECT) already in removal list - ID: 999
```

---

## Standards Applicability

### Behavior by Classification Standard

| Standard | Class Objects | Terms | "Class" Property Removal Method |
|----------|--------------|-------|--------------------------------|
| IEC 61355 | ✅ Used | ❌ Not used | Explicitly removed from FILE definitions |
| eCl@ss | ✅ Used | ❌ Not used | Explicitly removed from FILE definitions |
| PDMC-Sample | ✅ Used | ❌ Not used | Explicitly removed from FILE definitions |
| **Uniclass** | ⚠️ Optional | ✅ **Term-as-Class** | **Explicitly removed from FILE definitions** |

**Why Explicit Removal is Universal:**
- The "Class" property (CLSOBJECT) is stored on the FILE entity, not on the Custom Entity (Class Object or Term)
- `mGetAllClsPrpNames()` and `mGetTermPrpNames()` return properties from the Custom Entity
- Therefore, CLSOBJECT must be explicitly looked up in FILE property definitions and removed separately
- This applies to ALL standards and ALL classification types (Class Objects and Terms)

---

## Technical Architecture

### Property Types in Classification System

```
FILE Entity
  ├─ System Properties (_FileName, _RevisionLabel, etc.)
  ├─ Custom Entity Properties (from Class Object or Term assignment)
  │   ├─ Code
  │   ├─ Title
  │   ├─ Description
  │   ├─ Title ES (Spanish)
  │   └─ ... (other properties copied FROM the Class/Term object)
  └─ FILE Property Definitions (exist on FILE entity itself)
      └─ Class (CLSOBJECT) ← Stores name of assigned Class/Term
          └─ Backed by: $Prop["_XLTN_CLSOBJECT"].Value
          └─ Source: FILE property definition (not Custom Entity)
```

**Assignment Process:**
1. User selects Class Object "Mechanical Components" or Term "Foundation Works"
2. System sets `$Prop["_XLTN_CLSOBJECT"].Value = "Mechanical Components"` (or "Foundation Works")
3. System calls `UpdateFilePropertyDefinitions($mPropsAdd, [], ...)` with:
   - Custom Entity properties (Code, Title, etc.) - copied FROM Class/Term
   - **CLSOBJECT property** - FILE property definition to display "Class" = "Mechanical Components"

**Removal Process (FIXED):**
1. System gets Class/Term properties via `mGetAllClsPrpNames()` or `mGetTermPrpNames()`
2. System adds Custom Entity property IDs to removal list
3. **[NEW]** System looks up CLSOBJECT property in FILE property definitions (by SysName)
4. **[NEW]** System adds CLSOBJECT.Id to removal list (if not already present)
5. System calls `UpdateFilePropertyDefinitions([], $mPropsRemove, ...)`
6. Both Custom Entity properties AND "Class" FILE property removed

---

## Error Handling

### Scenarios Covered

1. **Property Not Found:**
   ```powershell
   if ($mClassPropertyDef) { ... }
   else {
       $dsDiag.Trace("  [WARNING] 'Class' property (CLSOBJECT) not found in FILE property definitions")
   }
   ```
   - **Cause:** CLSOBJECT not defined in Vault database
   - **Impact:** Removal continues without error
   - **User Impact:** Term properties still removed

2. **API Call Failure:**
   ```powershell
   catch {
       $dsDiag.Trace("  [ERROR] Failed to find/add Class property for removal: $($_.Exception.Message)")
   }
   ```
   - **Cause:** Vault API exception (connection, permissions, etc.)
   - **Impact:** Removal continues without adding CLSOBJECT
   - **User Impact:** "Class" property may remain on file

### Validation
- All errors logged to `$dsDiag` trace
- User receives generic error message if `UpdateFilePropertyDefinitions` fails
- No silent failures - all issues traceable via logs

---

## Backward Compatibility

### Impact on Existing Installations

| Scenario | Impact | Action Required |
|----------|--------|-----------------|
| IEC 61355 standard | ✅ **Improved** - "Class" property now properly removed | Update to v1.2.2 |
| eCl@ss standard | ✅ **Improved** - "Class" property now properly removed | Update to v1.2.2 |
| PDMC-Sample standard | ✅ **Improved** - "Class" property now properly removed | Update to v1.2.2 |
| Uniclass - Class Objects | ✅ **Improved** - "Class" property now properly removed | Update to v1.2.2 |
| **Uniclass - Terms (NEW workflow)** | ✅ **Fixed** - "Class" property now properly removed | Update to v1.2.2 |

**Files with Leftover "Class" Properties:**
- If upgrading from any version before v1.2.2, files may have orphaned "Class" properties from incomplete removals
- **Remedy:** Re-run "Remove Classification" workflow with v1.2.2 - will now properly remove "Class" property
- Applies to ALL standards (not just Uniclass)

---

## Version History

### v1.2.0 (Previous)
- ✅ Added Uniclass Term-as-Class assignment workflow
- ❌ Incomplete removal - "Class" property not removed

### v1.2.1 (Previous)
- ✅ Fixed object type detection in removal
- ❌ Still incomplete - "Class" property not removed

### v1.2.2 (Current)
- ✅ **Explicit removal of "Class" property (CLSOBJECT)**
- ✅ Works for both Class Objects and Terms
- ✅ Proper error handling and logging
- ✅ Backward compatible with all standards

---

## Related Changes
- **v1.0.0:** Term ES (Spanish) property support
- **v1.1.0:** Code property transfer enabled
- **v1.1.1:** Is Manual Entry filter property
- **v1.1.2:** Classification removal fix (mGetAllClsPrpNames)
- **v1.2.0:** Uniclass Term-as-Class assignment
- **v1.2.1:** Uniclass Term-as-Class removal detection
- **v1.2.2:** ← THIS CHANGE

---

## Files Modified
- ✅ `Vault.Custom/addinVault/ADSK.TS.FileClassification.ps1` (mRemoveClassification function, lines 671-722)

## Files Referenced
- `en-US/PropertyTranslations.xml` (CLSOBJECT → "Class")
- `de-DE/PropertyTranslations.xml` (CLSOBJECT → "Klasse")

---

## Deployment Notes
1. Backup existing `ADSK.TS.FileClassification.ps1`
2. Deploy updated PowerShell script
3. Restart Vault Explorer clients
4. Test removal workflow with Uniclass Terms
5. Monitor diagnostic logs for "[EXPLICIT] Removing 'Class' property" messages

---

## Support Information
- **Primary Function:** `mRemoveClassification()`
- **Diagnostic Keyword:** `[EXPLICIT]` (in trace logs)
- **Property Internal Name:** `CLSOBJECT`
- **Property Display Name:** `Class` (EN) / `Klasse` (DE)
- **Vault API:** `PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")`
- **Entity Class:** `FILE`

---

**Change Complete** ✅
