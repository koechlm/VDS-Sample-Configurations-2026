# "Is Manual Entry" Property Implementation

## Overview
Implemented "Is Manual Entry" as a classification-level filter property for Term objects. This property is configured as metadata that describes the classification structure and is NOT transferred to files.

## Purpose
The "Is Manual Entry" property serves as a filter/flag on Term objects to indicate whether a term requires manual entry or selection. This is useful for:
- Filtering Term catalogs by entry type
- Searching for terms that require manual data entry
- Organizing terms based on data entry requirements
- Classification hierarchy management and filtering

## Implementation Type
**Classification-Level Property (Metadata/Filter)**
- Property is defined on Term custom objects
- Property is used for filtering and classification management
- Property is **NOT** transferred to files during classification assignment
- Property is included in the exclusion list

## Files Modified

### 1. **en-US\UIStrings.xml**
**Location**: After ClassTerms_12a (Term ES)

**Change**:
```xml
<UIString ID="ClassTerms_12b">Is Manual Entry</UIString>
```

### 2. **en-US\PropertyTranslations.xml**
**Location**: After TERM-ES translation

**Change**:
```xml
<PropertyTranslation Name="IS-MANUAL-ENTRY">Is Manual Entry</PropertyTranslation>
```

### 3. **de-DE\UIStrings.xml**
**Location**: After ClassTerms_12a (Begriff ES)

**Change**:
```xml
<UIString ID="ClassTerms_12b">Ist manuelle Eingabe</UIString>
```

### 4. **de-DE\PropertyTranslations.xml**
**Location**: After TERM-ES translation

**Change**:
```xml
<PropertyTranslation Name="IS-MANUAL-ENTRY">Ist manuelle Eingabe</PropertyTranslation>
```

### 5. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**
**Location**: Line 43 in `mInitializeClassificationTab` function

**Change**: Added `$UIString["ClassTerms_12b"]` to exclusion list

**BEFORE**:
```powershell
$Global:mClsPropNames = (
    $UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
    $UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
    $UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsLevelCode"], 
    $UIString["Comments"], $UIString["CommentsDE"] )
```

**AFTER**:
```powershell
$Global:mClsPropNames = (
    $UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
    $UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
    $UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["ClassTerms_12b"], $UIString["Adsk.QS.ClsLevelCode"], 
    $UIString["Comments"], $UIString["CommentsDE"] )
```

## Property Configuration

### UIString ID
- **ID**: `ClassTerms_12b`
- **English**: "Is Manual Entry"
- **German**: "Ist manuelle Eingabe"

### Property Translation Name
- **Internal Name**: `IS-MANUAL-ENTRY`
- **Display Name (EN)**: "Is Manual Entry"
- **Display Name (DE)**: "Ist manuelle Eingabe"

### Property Details
| Attribute | Value |
|-----------|-------|
| **Property Name** | Is Manual Entry |
| **Internal Name** | IS-MANUAL-ENTRY |
| **Entity Type** | Custom Object (Term) |
| **Data Type** | Boolean (typically) |
| **Purpose** | Filter/metadata for classification management |
| **Transferred to Files** | ❌ NO (excluded) |
| **UIString ID** | ClassTerms_12b |

## Technical Details

### Exclusion List Behavior
The `$Global:mClsPropNames` array defines properties that should **NOT** be transferred to files. "Is Manual Entry" is now part of this exclusion list.

**Processing Flow**:
1. **mGetClsPrpNames()** - Filters out "Is Manual Entry" when retrieving class property names
2. **mGetTermPrpNames()** - Retrieves all Term properties, but "Is Manual Entry" gets filtered during merge
3. **mGetClsDfltValues()** - Excludes "Is Manual Entry" from preview grid
4. **mGetTermDfltValues()** - Shows "Is Manual Entry" in Term grid (for viewing only)
5. **mSelectClassification()** - Excludes "Is Manual Entry" from file transfer

### Complete Exclusion List
Properties that describe classification structure and are NOT transferred to files:

| Property Display Name | UIString ID | Purpose |
|----------------------|-------------|---------|
| Segment (Level 1) | Adsk.QS.ClsLevel_01 | Classification hierarchy |
| Main Group (Level 2) | Adsk.QS.ClsLevel_02 | Classification hierarchy |
| Group (Level 3) | Adsk.QS.ClsLevel_03 | Classification hierarchy |
| Sub Group (Level 4) | Adsk.QS.ClsLevel_04 | Classification hierarchy |
| Class | Adsk.QS.ClsObject | Classification object type |
| Standard | Adsk.QS.ClsStandard | Classification standard |
| Term DE | ClassTerms_09 | German term name |
| Term EN | ClassTerms_10 | English term name |
| Term FR | ClassTerms_11 | French term name |
| Term IT | ClassTerms_12 | Italian term name |
| Term ES | ClassTerms_12a | Spanish term name |
| **Is Manual Entry** | **ClassTerms_12b** | **Manual entry flag** ✨ NEW |
| Level Code | Adsk.QS.ClsLevelCode | Classification level code |
| Comments | Comments | General comments |
| CommentsDE | CommentsDE | German comments |

## Use Cases

### Use Case 1: Filter Terms Requiring Manual Entry
```powershell
# Search for terms where "Is Manual Entry" = True
$manualTerms = mSearchCustentOfCat("Term") | Where-Object { 
    (mGetCustentPropValue $_.Id "Is Manual Entry") -eq $true 
}
```

### Use Case 2: Catalog Organization
- Create Terms with "Is Manual Entry" = True for terms requiring user input
- Create Terms with "Is Manual Entry" = False for predefined/automatic terms
- Filter catalog displays based on this flag

### Use Case 3: Workflow Automation
- Check "Is Manual Entry" flag before auto-populating properties
- Route to manual entry workflows when flag is True
- Skip to automatic workflows when flag is False

### Use Case 4: Search and Discovery
- Users can search for terms that require manual entry
- Administrators can bulk-update Terms based on entry type
- Reports can group Terms by entry type

## Behavior in Classification Dialogs

### In "Select Classification" Dialog
When viewing a Term object:
- ✅ "Is Manual Entry" property **WILL** appear in the Term properties grid (for viewing)
- ✅ Users can see the flag value to understand if manual entry is needed
- ❌ "Is Manual Entry" property **WILL NOT** transfer to the file when classification is applied

### Example Dialog Display
```
┌─ Class Term Properties ─────────────────────────┐
│ Property Name        │ Property Value           │
│─────────────────────┼──────────────────────────┤
│ Code                │ TERM-001                 │
│ Term DE             │ Manueller Eintrag        │
│ Term EN             │ Manual Entry             │
│ Is Manual Entry ✨  │ True                     │  ← Visible but not transferred
│ Description         │ Requires user input      │
└──────────────────────────────────────────────────┘
```

### After Classification Applied to File
```
┌─ FILE PROPERTIES ───────────────────────────────┐
│ Property Name        │ Property Value           │
│─────────────────────┼──────────────────────────┤
│ Code                │ TERM-001                 │
│ Title               │ Manual Entry             │
│ Description         │ Requires user input      │
│                                                  │
│ ❌ Is Manual Entry NOT included                │  ← Filtered out
└──────────────────────────────────────────────────┘
```

## Administrator Setup

### Required Actions

1. **Create Property Definition in Vault**:
   - Property Name: "Is Manual Entry"
   - Internal Name: "IS-MANUAL-ENTRY"
   - Entity Type: Custom Object
   - Data Type: Boolean (or Text: "True"/"False")
   - Category Association: Term category

2. **Add Property to Term Objects**:
   - Edit existing Term custom objects
   - Add "Is Manual Entry" property
   - Set value to True or False as appropriate

3. **Configure Property Behavior**:
   - Set default value (typically False)
   - Configure property visibility in Vault UI
   - Add to custom object definition layouts

4. **Update Workflows** (Optional):
   - Create search filters using "Is Manual Entry"
   - Update custom commands to check this flag
   - Add automation logic based on flag value

### Property Definition Example

**In Vault Property Service**:
- Display Name: `Is Manual Entry`
- System Name: `IS-MANUAL-ENTRY`
- Data Type: `Boolean` or `Single Line Text`
- Default Value: `False` or `No`
- Required: No
- Single Value: Yes

**Suggested List Values (if using Text type)**:
- `True` / `False`
- `Yes` / `No`
- `Manual` / `Automatic`

## Testing Recommendations

### Test 1: Property Visibility
- [ ] Open a Term object in Vault
- [ ] Verify "Is Manual Entry" property appears in property list
- [ ] Set value to True/False
- [ ] Save and reload - verify value persists

### Test 2: Classification Dialog Display
- [ ] Open "Select Classification" dialog
- [ ] Navigate to a Term with "Is Manual Entry" populated
- [ ] Verify property appears in Term properties grid
- [ ] Verify you can see the True/False value

### Test 3: File Transfer Exclusion
- [ ] Select a Term with "Is Manual Entry" = True
- [ ] Apply classification to a file
- [ ] Open file properties
- [ ] Verify "Is Manual Entry" is **NOT** on the file
- [ ] Verify other Term properties (Code, Title, etc.) ARE on the file

### Test 4: Filtering
- [ ] Create search for Terms where "Is Manual Entry" = True
- [ ] Verify correct Terms are returned
- [ ] Create search for Terms where "Is Manual Entry" = False
- [ ] Verify correct Terms are returned

### Test 5: Localization
- [ ] Switch Vault to German locale
- [ ] Verify property displays as "Ist manuelle Eingabe"
- [ ] Switch back to English
- [ ] Verify property displays as "Is Manual Entry"

## Common Questions

**Q: Why isn't "Is Manual Entry" transferred to files?**  
A: It's a classification management property that describes the Term itself, not the file. It's used for filtering and organizing the classification catalog, not as file metadata.

**Q: Can I still see the "Is Manual Entry" value in the classification dialog?**  
A: Yes! It appears in the Term properties grid for viewing, so users can see if manual entry is required. It just won't be copied to the file.

**Q: Can I use this property for filtering in search?**  
A: Yes! Since it's defined on Term objects, you can search for Terms based on this property value.

**Q: What if I want this property on files?**  
A: Remove `$UIString["ClassTerms_12b"]` from the `$Global:mClsPropNames` exclusion list in line 43 of `ADSK.TS.FileClassification.ps1`. However, this would go against the intended design as a filter property.

**Q: Can I add this property to Class Objects too?**  
A: Yes, you can define the same property on Class Objects if needed. The exclusion logic will filter it out from file transfer regardless of the source.

## Related Properties

Similar classification-level filter/metadata properties:
- **Standard** - Which classification standard (IEC, eCl@ss, etc.)
- **Level Code** - Classification hierarchy code
- **Comments** - Administrative notes
- **Term language names** - Names of terms in the hierarchy

All of these are excluded from file transfer and serve classification management purposes.

## Version History
- **v1.0** (March 29, 2026): Initial implementation
  - Added "Is Manual Entry" property definition
  - Added to exclusion list as classification-level filter property
  - Localized for English and German

## Impact Summary

### ✅ What Changed
- "Is Manual Entry" can now be defined on Term objects
- Property appears in UIStrings and PropertyTranslations
- Property is properly filtered out during classification assignment
- Property is localized (EN/DE)

### ❌ What Did NOT Change
- File properties remain unchanged (property not transferred)
- Existing classification workflows continue as-is
- No impact on existing Terms or files
- Backward compatible

### 📊 Benefits
- Better organization of Term catalogs
- Ability to filter Terms by entry type
- Improved classification management
- Clear indication of manual entry requirements
- Search and reporting capabilities based on entry type

---

**Related Documentation:**
- See **CLASSIFICATION_CHANGES_SUMMARY.md** for overview of all classification changes
- See **CODE_PROPERTY_IMPLEMENTATION.md** for Code property details
- See **TERM_ES_IMPLEMENTATION_SUMMARY.md** for Term ES implementation
- See **CLASSIFICATION_PROPERTY_FLOW.md** for property flow diagrams
