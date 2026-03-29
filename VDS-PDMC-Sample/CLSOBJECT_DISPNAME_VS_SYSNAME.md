# CLSOBJECT Property Lookup - Display Name vs System Name

## The Critical Difference

### Why SysName Lookup Doesn't Work

**Problem:** Using `$_.SysName -eq "CLSOBJECT"` to find the FILE property returns `$null`

**Root Cause:** FILE property definitions in Vault may not have `SysName` populated with "CLSOBJECT"

### The Correct Solution

**Use DispName with UIString lookup:**
```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
```

---

## Property Definition Comparison

### Custom Entity Property (From Class/Term Objects)
```powershell
# Property on Class Object or Term
{
    PropDefId: 123
    SysName: "CLSOBJECT"           // From PropertyTranslations.xml Name attribute
    DispName: "Class"              // From PropertyTranslations.xml value
    EntityClassId: "CUSTENT"
}
```

### FILE Property (On Files)
```powershell
# Property on FILE
{
    Id: 999
    SysName: null or ""            // ⚠️ May not be populated!
    DispName: "Class"              // From UIString["Adsk.QS.Classification_00"]
    EntityClassId: "FILE"
}
```

**Key Insight:** The FILE property may not have SysName set to "CLSOBJECT", so we must use DispName for lookup!

---

## UIString Mapping Reference

### The Naming Matrix

| UIString Key | EN Value | DE Value | Usage Context |
|--------------|----------|----------|---------------|
| `Adsk.QS.ClsObject` | "Class Object" | "Class Object" | Custom Entity type name |
| `Adsk.QS.Classification_00` | "Class" | "Klasse" | **FILE property DispName** ⭐ |

### Why Two Different UIStrings?

```
Custom Entity Type:
  Name: "Class Object"
  UIString: Adsk.QS.ClsObject
  Used for: Custom entity definition lookup, UI labels
  
FILE Property:
  Name: "Class" (EN) / "Klasse" (DE)
  UIString: Adsk.QS.Classification_00
  Used for: FILE property definition lookup
  Backed by: _XLTN_CLSOBJECT
```

---

## Code Evolution - Debugging Journey

### Attempt 1 (FAILED):
```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.SysName -eq "CLSOBJECT" }
# Result: $mClassPropertyDef = $null
# Reason: FILE property SysName not populated
```

### Attempt 2 (CORRECT):
```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
# Result: $mClassPropertyDef found! ✅
# Reason: DispName is always populated, UIString provides language-aware matching
```

---

## Validation Checklist

### ✅ Correct Implementation Checklist

- [x] Use `GetPropertyDefinitionsByEntityClassId("FILE")` to get FILE property definitions
- [x] Use `$_.DispName` for filtering (NOT `$_.SysName`)
- [x] Use `$UIString["Adsk.QS.Classification_00"]` for language-aware matching (NOT `Adsk.QS.ClsObject`)
- [x] Add property ID to `$mPropsRemove` array
- [x] Clear `$Prop["_XLTN_CLSOBJECT"].Value = ""`
- [x] Handle missing property gracefully (log warning, don't fail)

### ❌ Common Mistakes to Avoid

- [ ] ~~Using `$_.SysName -eq "CLSOBJECT"`~~ (SysName may not be populated on FILE properties)
- [ ] ~~Using `$UIString["Adsk.QS.ClsObject"]`~~ (That's "Class Object", not "Class")
- [ ] ~~Using hardcoded "Class"~~ (Not language-aware, fails in DE-DE vaults)
- [ ] ~~Only adding to removal list without clearing `_XLTN_CLSOBJECT` value~~ (Value may persist)

---

## Language Support Verification

### English (en-US) Vault
```powershell
$UIString["Adsk.QS.Classification_00"] = "Class"
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq "Class" }
// ✅ Property found and removed
```

### German (de-DE) Vault
```powershell
$UIString["Adsk.QS.Classification_00"] = "Klasse"
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq "Klasse" }
// ✅ Property found and removed
```

### Why It Works Across Languages
- `$UIString["Adsk.QS.Classification_00"]` automatically returns the correct translated value
- DispName on FILE property matches the UIString value
- No hardcoded strings means full language support

---

## Related Configuration Files

### en-US/UIStrings.xml
```xml
<UIString ID="Adsk.QS.ClsObject">Class Object</UIString>        <!-- Custom Entity -->
<UIString ID="Adsk.QS.Classification_00">Class</UIString>        <!-- FILE Property ⭐ -->
```

### de-DE/UIStrings.xml
```xml
<UIString ID="Adsk.QS.ClsObject">Class Object</UIString>        <!-- Custom Entity -->
<UIString ID="Adsk.QS.Classification_00">Klasse</UIString>       <!-- FILE Property ⭐ -->
```

### en-US/PropertyTranslations.xml
```xml
<PropertyTranslation Name="CLSOBJECT">Class</PropertyTranslation>  <!-- Custom Entity properties -->
```

### de-DE/PropertyTranslations.xml
```xml
<PropertyTranslation Name="CLSOBJECT">Klasse</PropertyTranslation> <!-- Custom Entity properties -->
```

---

## Diagnostic Commands

### Check UIString Value
```powershell
$UIString["Adsk.QS.Classification_00"]
# Expected: "Class" (EN) or "Klasse" (DE)
```

### Check FILE Property Definitions
```powershell
$mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }

if ($mClassPropertyDef) {
    Write-Host "Found Class Property:"
    Write-Host "  Id: $($mClassPropertyDef.Id)"
    Write-Host "  SysName: '$($mClassPropertyDef.SysName)'"  # May be null/empty
    Write-Host "  DispName: '$($mClassPropertyDef.DispName)'"  # Should be "Class" or "Klasse"
}
```

### Check if Property is on File
```powershell
$Prop["_XLTN_CLSOBJECT"].Value
# If has classification: Returns class/term name
# If no classification: Returns empty string
```

---

## Summary

### The Key Learnings

1. **SysName is unreliable for FILE properties** - May not be populated
2. **DispName must be used** - Always populated, matches UIString
3. **UIString provides language support** - `Adsk.QS.Classification_00` returns correct translation
4. **Two steps required:** Add to removal list AND clear `_XLTN_CLSOBJECT` value
5. **Comment update explains edge case:** Property may relate to file category and can't be removed (clearing value ensures unclassification)

---

**Status:** ✅ VALIDATED AND CORRECTED  
**Line 708:** Uses `$_.DispName -eq $UIString["Adsk.QS.Classification_00"]` (CORRECT)  
**Line 721:** Clears `$Prop["_XLTN_CLSOBJECT"].Value` (CORRECT)  
**Date:** March 29, 2026
