# Spanish Language Support - Custom Entity Classification Module

## Version
**Version:** 1.3.1  
**Date:** April 1, 2026  
**Feature:** Spanish (ES) language support for Term Catalog  
**File Modified:** `ADSK.QS.CustentClassification.psm1`  
**Status:** ✅ COMPLETE

---

## Overview

Added complete Spanish (ES) language support to the Custom Entity Classification PowerShell module, matching the existing implementation for German (DE), English (EN), French (FR), and Italian (IT).

---

## Changes Made

### 1. CatalogData Class - Added Term_ES Property

**Location:** Lines 10-16

**Change:**
```powershell
class CatalogData {
	[string]$Term_DE
	[string]$Term_EN
	[string]$Term_FR
	[string]$Term_IT
	[string]$Term_ES  # ← ADDED
}
```

**Purpose:** Adds Spanish term field to the data class used for catalog search results.

---

### 2. Search Conditions Counter - Added chkES Checkbox Check

**Location:** Line 98

**Change:**
```powershell
# check the language columns/properties to search in
If ($dsWindow.FindName("chkDE").IsChecked -eq $true) { $_NumConds += 1 } #default = not checked
If ($dsWindow.FindName("chkEN").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkFR").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkIT").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkES").IsChecked -eq $true) { $_NumConds += 1 }  # ← ADDED
```

**Purpose:** Increments search conditions counter when Spanish checkbox is selected.

---

### 3. Search Condition Creation - Added Spanish Search Term

**Location:** Lines 133-136

**Change:**
```powershell
If ($dsWindow.FindName("chkES").IsChecked -eq $true) {
	$srchConds[$_i] = mCreateClsSearchCond $UIString["ClassTerms_12a"] $mSearchText1 "OR"  #Term ES
	$_i += 1
}
```

**UIString Key:** `ClassTerms_12a` = "Term ES"

**Purpose:** Adds Spanish term search condition to Vault search when checkbox is enabled.

---

### 4. Catalog Data Population - Added Term_ES Assignment

**Location:** Line 216

**Change:**
```powershell
#create a row for the element and it's properties
$row = New-Object CatalogData
$row.Term_DE = $props[$UIString["ClassTerms_09"]]  # Term DE
$row.Term_EN = $props[$UIString["ClassTerms_10"]]  # Term EN
$row.Term_FR = $props[$UIString["ClassTerms_11"]]  # Term FR
$row.Term_IT = $props[$UIString["ClassTerms_12"]]  # Term IT
$row.Term_ES = $props[$UIString["ClassTerms_12a"]]  # Term ES  # ← ADDED
```

**Purpose:** Populates Spanish term value from Vault custom entity properties into search result row.

---

### 5. AutoCAD Window - Title ES Property Assignment

**Location:** Lines 286-289

**Change:**
```powershell
Try {
	$Prop["Title IT"].Value = $mSelectedItem.Term_IT
}
catch { $dsDiag.Trace("Title IT does not exist") }

Try {
	$Prop["Title ES"].Value = $mSelectedItem.Term_ES  # ← ADDED
}
catch { $dsDiag.Trace("Title ES does not exist") }
```

**Purpose:** Assigns Spanish term to "Title ES" property when term is selected in AutoCAD context.

---

### 6. Inventor Window - Title ES Property Assignment

**Location:** Lines 326-329

**Change:**
```powershell
Try {
	$Prop["Title IT"].Value = $mSelectedItem.Term_IT
}
catch { $dsDiag.Trace("Title IT does not exist") }

Try {
	$Prop["Title ES"].Value = $mSelectedItem.Term_ES  # ← ADDED
}
catch { $dsDiag.Trace("Title ES does not exist") }
```

**Purpose:** Assigns Spanish term to "Title ES" property when term is selected in Inventor context.

---

### 7. Vault File Window - Title ES Property Assignment (XLTN)

**Location:** Lines 366-369

**Change:**
```powershell
Try {
	$Prop["_XLTN_TITLE-IT"].Value = $mSelectedItem.Term_IT
}
catch { $dsDiag.Trace("Title IT does not exist") }

Try {
	$Prop["_XLTN_TITLE-ES"].Value = $mSelectedItem.Term_ES  # ← ADDED
}
catch { $dsDiag.Trace("Title ES does not exist") }
```

**Property Name:** `_XLTN_TITLE-ES` (Vault context uses XLTN prefix for translated properties)

**Purpose:** Assigns Spanish term to "_XLTN_TITLE-ES" property when term is selected in Vault File window.

---

## UIString Keys Used

| UIString ID | English Value | German Value | Purpose |
|-------------|---------------|--------------|---------|
| `ClassTerms_12a` | Term ES | Begriff ES | Spanish term property name |

---

## Property Mappings

### AutoCAD & Inventor Context
- **Property:** `Title ES`
- **Source:** `$mSelectedItem.Term_ES`

### Vault File Context
- **Property:** `_XLTN_TITLE-ES`
- **Source:** `$mSelectedItem.Term_ES`

---

## Testing Checklist

### Prerequisites
1. ✅ Vault has custom entities (Terms) with "Term ES" property populated
2. ✅ UIStrings.xml contains `ClassTerms_12a` definition
3. ✅ XAML dialog has `chkES` checkbox control for Spanish language filter

### Test Scenarios

#### Test 1: Search with Spanish Filter
1. Open Term Catalog search dialog
2. Check the "ES" checkbox (chkES)
3. Enter search text
4. Click Search
5. **Expected:** Search includes Spanish terms in results

#### Test 2: Term Selection - AutoCAD
1. Open AutoCAD file dialog with term catalog
2. Search and select a term with Spanish translation
3. Click "Adopt" button
4. **Expected:** `Title ES` property populated with Spanish term value

#### Test 3: Term Selection - Inventor
1. Open Inventor file dialog with term catalog
2. Search and select a term with Spanish translation
3. Click "Adopt" button
4. **Expected:** `Title ES` property populated with Spanish term value

#### Test 4: Term Selection - Vault File Window
1. Open Vault file edit dialog with term catalog
2. Search and select a term with Spanish translation
3. Click "Adopt" button
4. **Expected:** `_XLTN_TITLE-ES` property populated with Spanish term value

#### Test 5: DataGrid Display
1. Search for terms with all language checkboxes enabled (DE, EN, FR, IT, ES)
2. View search results in DataGrid
3. **Expected:** `Term_ES` column displays Spanish term values

---

## Dependencies

### XAML Files (Require chkES Control)
The following XAML files must have a CheckBox control named `chkES` for Spanish language filtering:

- `ADSK.QS.InventorWindow.xaml` (if Term Catalog enabled)
- `ADSK.QS.AutoCADWindow.xaml` (if Term Catalog enabled)
- `ADSK.QS.FileWindow.xaml` (if Term Catalog enabled)
- Any other dialogs using Term Catalog search

**Control Example:**
```xml
<CheckBox Name="chkES" Content="{Binding UIString[ClassTerms_12a]}" />
```

### Vault Property Definitions
The following properties must exist in Vault:

**Custom Entity (Term) Properties:**
- `Term ES` (ClassTerms_12a)

**File Properties:**
- `Title ES` (for AutoCAD/Inventor files)
- `_XLTN_TITLE-ES` (for Vault File context)

---

## Related UIStrings

All UIStrings.xml files (en-US, de-DE) already contain the Spanish language support:

**en-US/UIStrings.xml:**
```xml
<UIString ID="ClassTerms_12a">Term ES</UIString>
```

**de-DE/UIStrings.xml:**
```xml
<UIString ID="ClassTerms_12a">Begriff ES</UIString>
```

---

## Error Handling

All Spanish term property assignments use Try-Catch blocks to gracefully handle missing properties:

```powershell
Try {
	$Prop["Title ES"].Value = $mSelectedItem.Term_ES
}
catch { 
	$dsDiag.Trace("Title ES does not exist") 
}
```

**Behavior:**
- If property doesn't exist: Logs diagnostic message, continues execution
- If property exists: Assigns Spanish term value
- No user-facing errors displayed

---

## Deployment Notes

### Files to Deploy
1. **Modified PowerShell Module:**
   - `Vault.Custom\addinVault\ADSK.QS.CustentClassification.psm1`

### XAML Updates (If Not Already Present)
2. **Add chkES Checkbox** to XAML files that use Term Catalog search
3. **Bind to DataGrid** if Term_ES column should be displayed

### Vault Configuration
4. **Add Property Definitions:**
   - Custom Entity Property: "Term ES"
   - File Properties: "Title ES" and "_XLTN_TITLE-ES"
5. **Populate Data:** Add Spanish translations to existing Term custom entities

### Restart Requirements
- ✅ Restart Vault Explorer clients
- ✅ Restart Inventor (if using Term Catalog)
- ✅ Restart AutoCAD (if using Term Catalog)
- ❌ No Vault server restart required

---

## Language Coverage Summary

| Language | Code | Property Suffix | UIString Key | Status |
|----------|------|----------------|--------------|--------|
| German | DE | -DE | ClassTerms_09 | ✅ Supported |
| English | EN | -EN | ClassTerms_10 | ✅ Supported |
| French | FR | -FR | ClassTerms_11 | ✅ Supported |
| Italian | IT | -IT | ClassTerms_12 | ✅ Supported |
| **Spanish** | **ES** | **-ES** | **ClassTerms_12a** | **✅ NEW** |

---

## Implementation Consistency

All five languages (DE, EN, FR, IT, ES) now follow the same pattern:

1. ✅ Property in CatalogData class
2. ✅ Checkbox condition counter increment
3. ✅ Search condition creation with OR operator
4. ✅ Data row population from Vault properties
5. ✅ Property assignment in AutoCAD context
6. ✅ Property assignment in Inventor context
7. ✅ Property assignment in Vault File context
8. ✅ Try-Catch error handling
9. ✅ Diagnostic trace logging

---

## Future Enhancements

### Potential Additional Languages
To add more languages (e.g., Portuguese, Chinese), replicate the same pattern:

1. Add property to `CatalogData` class: `[string]$Term_XX`
2. Add checkbox check: `If ($dsWindow.FindName("chkXX").IsChecked -eq $true)`
3. Add search condition with new UIString key
4. Add row population: `$row.Term_XX = $props[$UIString["ClassTerms_XX"]]`
5. Add property assignments in all three contexts (AutoCAD, Inventor, FileWindow)
6. Update UIStrings.xml files with new language keys
7. Create Vault property definitions

---

## Support Information

**Module File:** `ADSK.QS.CustentClassification.psm1`  
**Function Modified:** `mSearchTerms()`, `m_SelectTerm()`  
**Class Modified:** `CatalogData`  
**UIString Keys:** `ClassTerms_12a` (Term ES)  
**Property Names:**
- `Title ES` (AutoCAD/Inventor)
- `_XLTN_TITLE-ES` (Vault File)

---

**Change Complete** ✅  
**Version:** 1.3.1  
**User Benefit:** Full Spanish language support for term catalog search and property assignment  
**Date:** April 1, 2026
