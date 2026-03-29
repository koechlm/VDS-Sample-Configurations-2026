# Term ES (Spanish) Implementation Summary

## Overview
Added support for Spanish language terms (Term ES) and corresponding Spanish titles (Title ES) throughout the Vault Data Standard classification system.

## Files Modified

### 1. **en-US\UIStrings.xml**
- Added: `<UIString ID="ClassTerms_12a">Term ES</UIString>` after ClassTerms_12

### 2. **en-US\PropertyTranslations.xml**
- Added: `<PropertyTranslation Name="TERM-ES">Term ES</PropertyTranslation>` after TERM-IT
- Added: `<PropertyTranslation Name="TITLE-ES">Title ES</PropertyTranslation>` after TITLE-IT

### 3. **de-DE\UIStrings.xml**
- Added: `<UIString ID="ClassTerms_12a">Begriff ES</UIString>` after ClassTerms_12

### 4. **de-DE\PropertyTranslations.xml**
- Added: `<PropertyTranslation Name="TERM-ES">Begriff ES</PropertyTranslation>` after TERM-IT
- Added: `<PropertyTranslation Name="TITLE-ES">Titel ES</PropertyTranslation>` after TITLE-IT

### 5. **Vault.Custom\addinVault\ADSK.TS.FileClassification.ps1**

#### Change 1: Added Term ES to classification property names (Line ~43)
```powershell
$Global:mClsPropNames = (
    $UIString["Adsk.QS.ClsLevel_01"], $UIString["Adsk.QS.ClsLevel_02"], $UIString["Adsk.QS.ClsLevel_03"], 
    $UIString["Adsk.QS.ClsLevel_04"], $UIString["Adsk.QS.ClsObject"], $UIString["Adsk.QS.ClsStandard"], $UIString["ClassTerms_09"], 
    $UIString["ClassTerms_10"], $UIString["ClassTerms_11"], $UIString["ClassTerms_12"], $UIString["ClassTerms_12a"], $UIString["Adsk.QS.ClsCode"], $UIString["Adsk.QS.ClsLevelCode"], 
    $UIString["Comments"], $UIString["CommentsDE"] )
```

#### Change 2: Added Term ES → Title ES mapping in mSelectClassification function (Line ~520)
```powershell
elseif ($propertyName -eq "Term ES") {
    $propertyName = "Title ES"
    $dsDiag.Trace("Mapped 'Term ES' to 'Title ES'")
}
```

## Property Mapping (when "Copy Term → Title" checkbox is checked)

| Source Property | Target Property |
|-----------------|-----------------|
| Term DE         | Title DE        |
| Term EN         | Title           |
| Term FR         | Title FR        |
| Term IT         | Title IT        |
| **Term ES**     | **Title ES**    |

## Usage

### In Vault Custom Object Properties
When defining Term objects in Vault, users can now add Spanish translations using the "Term ES" property.

### In File Classification Dialog
1. When assigning classification to files, if a Term object has "Term ES" defined, it will appear in the Term properties grid
2. When the "Copy Term → Title Values (Multi-Languages)" checkbox is checked:
   - The Term ES value will be automatically copied to Title ES property on the file
   - This happens alongside the other language mappings (DE, EN, FR, IT)

### Localization
- English locale: Displays as "Term ES" and "Title ES"
- German locale: Displays as "Begriff ES" and "Titel ES"

## Next Steps for Vault Administrator

1. **Add Property Definition** (if not already exists):
   - In Vault Professional, add a new property definition "Term ES" to Custom Object properties
   - Add a new property definition "Title ES" to File properties
   - Associate these properties with the appropriate entity categories

2. **Update Existing Term Objects**:
   - Edit existing Term custom objects to add Spanish translations in the "Term ES" field

3. **Test the Workflow**:
   - Create or edit a Term object with Term ES populated
   - Assign this Term to a file using the classification dialog
   - Verify that with the checkbox checked, Term ES values copy to Title ES

## Technical Notes

- The UIString ID for Term ES is `ClassTerms_12a` (inserted between ClassTerms_12 and ClassTerms_13 to maintain compatibility)
- The property internal names use the format `TERM-ES` and `TITLE-ES` following the existing convention
- All language mappings are case-sensitive string comparisons
- Diagnostic traces are logged when property mappings occur
