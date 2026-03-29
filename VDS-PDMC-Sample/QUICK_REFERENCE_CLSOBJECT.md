# ⚡ QUICK REFERENCE - CLSOBJECT Removal Fix

## The Solution (One Line!)

```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
$mPropsRemove += $mClassPropertyDef.Id
```

That's it! Do NOT clear the value.

---

## 🎯 The Three Critical Discoveries

### 1️⃣ Use DispName, NOT SysName
```powershell
// ❌ WRONG: $_.SysName -eq "CLSOBJECT"
// ✅ RIGHT: $_.DispName -eq $UIString["Adsk.QS.Classification_00"]
```
**Reason:** FILE properties don't have SysName reliably populated

### 2️⃣ Use Correct UIString Key
```powershell
// ❌ WRONG: $UIString["Adsk.QS.ClsObject"] = "Class Object"
// ✅ RIGHT: $UIString["Adsk.QS.Classification_00"] = "Class"
```
**Reason:** Different keys for Custom Entity vs FILE property

### 3️⃣ Do NOT Clear the Value
```powershell
// ❌ WRONG: $Prop["_XLTN_CLSOBJECT"].Value = ""
// ✅ RIGHT: Leave value as-is, only add to removal list
```
**Reason:** Post-close event will re-add properties with cleared values

---

## 📋 Testing - 30 Second Check

1. **Assign:** File → Classification → Select Class/Term → Apply
2. **Verify:** File has "Class" property ✅
3. **Remove:** File → Classification → Remove → Confirm
4. **Verify:** File "Class" property GONE ✅

---

## 🔍 Diagnostic Log - What to Look For

**Expected Messages:**
```
[EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: 999, Display Name: Class
Total properties to remove: 15
Successfully removed 15 classification properties
```

**Should NOT See:**
```
Cleared _XLTN_CLSOBJECT value  // ← This line removed (lines 720-722)
```

---

## 🚨 What NOT to Do

### ❌ Don't Clear Values in Removal
```powershell
$Prop["_XLTN_CLSOBJECT"].Value = ""  // Post-close will re-add!
```

### ❌ Don't Use SysName
```powershell
$_.SysName -eq "CLSOBJECT"  // Not populated on FILE properties
```

### ❌ Don't Use Wrong UIString
```powershell
$UIString["Adsk.QS.ClsObject"]  // That's "Class Object", not "Class"
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `DATA_STANDARD_POST_CLOSE_EVENT_BEHAVIOR.md` | Post-close event explanation |
| `CLSOBJECT_DISPNAME_VS_SYSNAME.md` | SysName vs DispName troubleshooting |
| `UNICLASS_CLASS_PROPERTY_REMOVAL.md` | Main implementation guide |
| `FINAL_IMPLEMENTATION_SUMMARY.md` | Complete solution documentation |
| `QUICK_REFERENCE_CLSOBJECT.md` | ← This document |

---

## ✅ Deployment Ready

**Version:** 1.2.2  
**Status:** ✅ VALIDATED  
**Lines Modified:** 702-728  
**Lines Removed:** 720-722 (value clearing)  
**Ready for Production:** YES

---

**Key Takeaway:** Trust the Vault API to handle value clearing. Only queue the property for removal!
