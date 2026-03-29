# Classification System - Quick Reference Card

## ⚡ Version 1.2.2 - What's New

### Critical Fix: "Class" Property Removal
**Problem:** CLSOBJECT property left on files after removing Uniclass Term-as-Class  
**Solution:** Explicit lookup and removal of "Class" property from FILE property definitions  
**Impact:** ✅ Complete cleanup during classification removal

---

## 🔍 Quick Diagnostic Commands

### Check if "Class" Property is on File
```powershell
$Prop["_XLTN_CLSOBJECT"].Value  # Should be empty after removal
```

### View Removal Trace Log
Look for this message in diagnostic log:
```
[EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: 999, Display Name: Class
```

---

## 📋 Testing Quick Steps

### Uniclass Term-as-Class Full Test
1. **Assign:** Edit file → Classification → Select Uniclass → Choose Term → Apply
2. **Verify:** File has "Class" property = Term name ✅
3. **Remove:** Edit file → Classification → Remove
4. **Verify:** File "Class" property GONE ✅

---

## 🔧 Function Usage Matrix

| Function | Used For | Filters Properties | Use Case |
|----------|----------|-------------------|----------|
| `mGetClsPrpNames()` | Class assignment | ✅ YES | Add filtered properties to file |
| `mGetAllClsPrpNames()` | Class removal | ❌ NO | Remove ALL properties (including "Class") |
| `mGetTermPrpNames()` | Term assignment/removal | ❌ NO | Uniclass Term-as-Class workflow |

---

## 📦 Property Summary

### Properties That Transfer to Files
✅ Code (v1.1.0)  
✅ Title  
✅ Description  
✅ Term ES (v1.0.0)  
✅ Title ES (auto-mapped from Term ES)  
✅ **Class (CLSOBJECT)** - Stores assigned class/term name

### Properties That DON'T Transfer (Metadata)
❌ Level 1, 2, 3, 4  
❌ Standard  
❌ Is Manual Entry (v1.1.1)

---

## 🛠️ Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Class" property remains after removal | Version < 1.2.2 | Upgrade to v1.2.2 |
| Code property not on file | Version < 1.1.0 | Upgrade to v1.1.0 |
| Term ES not mapping | Missing localization | Check PropertyTranslations.xml |
| Uniclass Terms not selectable | Version < 1.2.0 | Upgrade to v1.2.0 |

---

## 📂 Files Modified (All Changes)

```
Vault.Custom/
  ├─ addinVault/
  │   └─ ADSK.TS.FileClassification.ps1 ⭐ PRIMARY FILE
  ├─ en-US/
  │   ├─ UIStrings.xml
  │   └─ PropertyTranslations.xml
  ├─ de-DE/
  │   ├─ UIStrings.xml
  │   └─ PropertyTranslations.xml
  └─ Documentation/
      ├─ TERM_ES_IMPLEMENTATION.md
      ├─ CODE_PROPERTY_TRANSFER.md
      ├─ IS_MANUAL_ENTRY_IMPLEMENTATION.md
      ├─ CLASSIFICATION_REMOVAL_FIX.md
      ├─ UNICLASS_TERM_AS_CLASS.md
      ├─ UNICLASS_CLASS_PROPERTY_REMOVAL.md ⭐ v1.2.2
      └─ COMPLETE_CHANGES_SUMMARY.md
```

---

## 🚀 Deployment Checklist

- [ ] Backup ADSK.TS.FileClassification.ps1
- [ ] Deploy updated script
- [ ] Restart Vault Explorer clients
- [ ] Test: Assign Uniclass Term → Remove → Verify "Class" property gone
- [ ] Monitor diagnostic logs for "[EXPLICIT]" messages

---

## 💡 Key Code Snippet (v1.2.2)

```powershell
# Explicit removal of "Class" property (CLSOBJECT)
$mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.SysName -eq "CLSOBJECT" }

if ($mClassPropertyDef) {
    $mPropsRemove += $mClassPropertyDef.Id
    $dsDiag.Trace("  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: $($mClassPropertyDef.Id)")
}
```

**Location:** `mRemoveClassification()` function, lines 703-718

---

## 📞 Support Keywords

**Search Logs For:**
- `[EXPLICIT]` - Class property removal
- `[Term ES Mapping]` - Spanish translation mapping
- `Uniclass: Applying Term as Class` - Term-as-Class assignment
- `Removing Uniclass Term-as-Class` - Term-as-Class removal

**Property Internal Names:**
- `CLSOBJECT` - "Class" property
- `TERM-ES` - Spanish term name
- `TITLE-ES` - Spanish title
- `IS-MANUAL-ENTRY` - Manual entry filter

---

**Current Version:** 1.2.2  
**Last Updated:** 2025-01-XX  
**Status:** ✅ All changes complete and tested
