# ClsCode Calculation - Complete Hierarchy Implementation

## Version
**Version:** 1.3.4  
**Date:** April 1, 2026  
**Feature:** Fixed ClsCode to include current object's ClsLevelCode  
**File Modified:** `ADSK.QS.CustentClassification.psm1`  
**Status:** ✅ COMPLETE

---

## Corrected Understanding

### ClsCode Composition

The complete ClsCode is built from **TWO sources**:

1. **Parent Hierarchy Codes** (from breadcrumb selections)
   - Level 1 custom entity's `ClsLevelCode` property
   - Level 2 custom entity's `ClsLevelCode` property
   - Level 3 custom entity's `ClsLevelCode` property
   - Level 4 custom entity's `ClsLevelCode` property

2. **Current Object's Code** (from the object being edited/created)
   - The current custom object's own `ClsLevelCode` property value

### Example Hierarchy

```
Classification Standard: IEC 61355
├─ Level 1: "Mechanical Engineering" (ClsLevelCode = "ME")
   ├─ Level 2: "Components" (ClsLevelCode = "COMP")
      ├─ Level 3: "Fasteners" (ClsLevelCode = "FAST")  ← Editing this object
         └─ Current Object's ClsLevelCode = "BOLT"

Final ClsCode = "ME_COMP_FAST_BOLT"
                 ↑    ↑     ↑    ↑
                 L1   L2    L3   Current Object
```

---

## Previous Implementation (INCORRECT)

### What Was Wrong

**Old Code:**
```powershell
function mBuildClsCode($mBreadCrumb, $levelMaps) {
	# ... loop through breadcrumb levels ...
	# Join all parts with underscore delimiter
	if ($codeParts.Count -gt 0) {
		return ($codeParts -join "_")  # Missing current object's code!
	}
}
```

**Problem:**
- Only included ClsLevelCode from breadcrumb parent levels
- Did NOT include the current object's own ClsLevelCode property
- Result: Incomplete classification code

**Example Error:**
```
Editing Level 3 object:
- Parent Level 1: "ME"
- Parent Level 2: "COMP"
- Current Object: ClsLevelCode = "FAST"

OLD Result: ClsCode = "ME_COMP"  ❌ (Missing "FAST")
NEW Result: ClsCode = "ME_COMP_FAST"  ✅ (Complete)
```

---

## New Implementation (CORRECT)

### Updated mBuildClsCode Function

**Location:** Lines 285-330

**Code:**
```powershell
# Helper function to build concatenated ClsCode from all selected breadcrumb levels
# PLUS the current object's own ClsLevelCode property value
function mBuildClsCode($mBreadCrumb, $levelMaps) {
	$codeParts = @()
	$clsLevelCodeKey = $UIString["Adsk.QS.ClsLevelCode"]
	
	# Iterate through breadcrumb children (skip index 0 which is the reset button)
	# These represent the PARENT hierarchy levels
	for ($i = 1; $i -le 4; $i++) {
		if ($mBreadCrumb.Children[$i] -and $mBreadCrumb.Children[$i].SelectedItem) {
			$selectedItem = $mBreadCrumb.Children[$i].SelectedItem
			$levelMap = $levelMaps[$i]
			
			if ($null -ne $levelMap -and $null -ne $selectedItem.Num) {
				$levelCode = $levelMap[$selectedItem.Num][$clsLevelCodeKey]
				
				# Only add non-empty level codes from parent hierarchy
				if (![string]::IsNullOrWhiteSpace($levelCode)) {
					$codeParts += $levelCode
				}
			}
		}
		else {
			# No more levels selected, stop building
			break
		}
	}
	
	# Add the CURRENT object's own ClsLevelCode property value at the end
	# This is the code for the object being edited/created
	if ($Prop[$clsLevelCodeKey]) {
		$currentObjCode = $Prop[$clsLevelCodeKey].Value
		if (![string]::IsNullOrWhiteSpace($currentObjCode)) {
			$codeParts += $currentObjCode
			$dsDiag.Trace("Added current object's ClsLevelCode: $currentObjCode")
		}
	}
	
	# Join all parts with underscore delimiter
	if ($codeParts.Count -gt 0) {
		$finalCode = $codeParts -join "_"
		$dsDiag.Trace("Built ClsCode from $($codeParts.Count) parts: $finalCode")
		return $finalCode
	}
	else {
		return $null
	}
}
```

**Key Changes:**
1. ✅ Added section to retrieve current object's `ClsLevelCode` property
2. ✅ Appends current object's code to the `$codeParts` array
3. ✅ Enhanced diagnostic logging showing both current code and total parts
4. ✅ Comments clarify parent vs. current object codes

---

## Property Change Handler Update

### Fixed Array Syntax

**Location:** `ADSK.QS.Default.ps1`, lines 257-262

**Old Code (Syntax Error):**
```powershell
$clsLevelProps = @(
	$UIString["Adsk.QS.ClsLevel_01"],
	$UIString["Adsk.QS.ClsLevel_02"],
	$UIString["Adsk.QS.ClsLevel_03"],
	$UIString["Adsk.QS.ClsLevel_04"]
	$UIString["Adsk.QS.ClsLevelCode"]  # Missing comma!
)
```

**New Code (Fixed):**
```powershell
$clsLevelProps = @(
	$UIString["Adsk.QS.ClsLevel_01"],
	$UIString["Adsk.QS.ClsLevel_02"],
	$UIString["Adsk.QS.ClsLevel_03"],
	$UIString["Adsk.QS.ClsLevel_04"],
	$UIString["Adsk.QS.ClsLevelCode"]  # ✅ Comma added
)
```

**Why This Matters:**
- Now when user edits the current object's `ClsLevelCode` property directly
- PropertyChanged event fires
- `mUpdateClsCode` is called
- ClsCode recalculates including the new value

---

## Complete Data Flow

### Scenario: Editing Level 3 Custom Object

**Initial State:**
```
Object Properties:
- _XLTN_CLSLEVEL1 = "Mechanical Engineering"
- _XLTN_CLSLEVEL2 = "Components"  
- _XLTN_CLSLEVEL3 = "Fasteners"
- ClsLevelCode = "M8-BOLT"

Breadcrumb After Initialization:
[Reset] [Mechanical Engineering] [Components] [Fasteners]
         └─ Code: ME            └─ Code: COMP  └─ Code: FAST
```

**mUpdateClsCode Execution:**

1. **Build Parent Level Maps:**
   ```
   _BreadcrumbLevelMaps[1] = { 
       "001" => { ClsLevelCode: "ME", Name: "Mechanical Engineering", ... }
   }
   _BreadcrumbLevelMaps[2] = { 
       "002" => { ClsLevelCode: "COMP", Name: "Components", ... }
   }
   _BreadcrumbLevelMaps[3] = { 
       "003" => { ClsLevelCode: "FAST", Name: "Fasteners", ... }
   }
   ```

2. **Call mBuildClsCode:**
   ```powershell
   $codeParts = @()
   
   # Loop through breadcrumb (parent hierarchy)
   $codeParts += "ME"    # From breadcrumb Level 1
   $codeParts += "COMP"  # From breadcrumb Level 2
   $codeParts += "FAST"  # From breadcrumb Level 3
   
   # Add current object's code
   $currentObjCode = $Prop["ClsLevelCode"].Value  # "M8-BOLT"
   $codeParts += "M8-BOLT"
   
   # Join with delimiter
   $finalCode = "ME_COMP_FAST_M8-BOLT"
   ```

3. **Set ClsCode Property:**
   ```powershell
   $Prop["ClsCode"].Value = "ME_COMP_FAST_M8-BOLT"
   ```

**Result:**
- ✅ Complete classification code displayed
- ✅ Includes full hierarchy path
- ✅ Includes current object's own code

---

## User Changes Current Object's ClsLevelCode

### Scenario: User edits ClsLevelCode field

**Action:**
```
User changes ClsLevelCode from "M8-BOLT" to "M10-BOLT"
```

**Event Flow:**
```
$Prop["ClsLevelCode"].Value = "M10-BOLT"
    ↓
PropertyChanged event fires
    ↓
Event handler detects change
    ↓
mUpdateClsCode() called
    ↓
mBuildClsCode() executes
    ├─ Reads parent codes: "ME", "COMP", "FAST"
    ├─ Reads current object code: "M10-BOLT"
    └─ Concatenates: "ME_COMP_FAST_M10-BOLT"
    ↓
$Prop["ClsCode"].Value updated
    ↓
ClsCode field refreshes in UI: "ME_COMP_FAST_M10-BOLT"
```

**Result:** ✅ ClsCode automatically synchronized with ClsLevelCode change

---

## Different Object Levels Examples

### Level 1 Object (Top of Hierarchy)

**Breadcrumb:**
```
[Reset] (no parents)
```

**Current Object:**
- ClsLevelCode = "ME"

**ClsCode Calculation:**
```powershell
$codeParts = @()
# No parent levels (breadcrumb is empty)
# Add current object's code
$codeParts += "ME"

Result: ClsCode = "ME"
```

---

### Level 2 Object

**Breadcrumb:**
```
[Reset] [Mechanical Engineering]
         └─ Code: "ME"
```

**Current Object:**
- ClsLevelCode = "COMP"

**ClsCode Calculation:**
```powershell
$codeParts = @("ME")      # Parent Level 1
$codeParts += "COMP"      # Current object
Result: ClsCode = "ME_COMP"
```

---

### Level 4 Object (Maximum Depth)

**Breadcrumb:**
```
[Reset] [Mechanical] [Components] [Fasteners] [Bolts]
         └─ ME        └─ COMP      └─ FAST     └─ BOLT
```

**Current Object:**
- ClsLevelCode = "M8"

**ClsCode Calculation:**
```powershell
$codeParts = @("ME", "COMP", "FAST", "BOLT")  # Parent Levels 1-4
$codeParts += "M8"                             # Current object
Result: ClsCode = "ME_COMP_FAST_BOLT_M8"
```

---

### Class Object (No Parent Hierarchy)

**Breadcrumb:**
```
[Reset] [Level1] [Level2] [Level3] [Level4]
         └─ L1    └─ L2    └─ L3    └─ L4
```

**Current Object (Class Object):**
- Category = "Class Object"
- ClsLevelCode = "CLASS-001"

**ClsCode Calculation:**
```powershell
$codeParts = @("L1", "L2", "L3", "L4")  # Parent Levels 1-4
$codeParts += "CLASS-001"                # Current class object
Result: ClsCode = "L1_L2_L3_L4_CLASS-001"
```

---

## Edge Cases

### Empty Parent Codes

**Scenario:**
```
Level 2 parent has empty ClsLevelCode
- Level 1: ClsLevelCode = "A"
- Level 2: ClsLevelCode = "" (empty)
- Current: ClsLevelCode = "C"
```

**Result:**
```powershell
$codeParts = @("A")  # Level 2 skipped (empty)
$codeParts += "C"    # Current object added
Result: ClsCode = "A_C"
```

---

### Empty Current Object Code

**Scenario:**
```
- Level 1: ClsLevelCode = "A"
- Level 2: ClsLevelCode = "B"
- Current: ClsLevelCode = "" (empty)
```

**Result:**
```powershell
$codeParts = @("A", "B")  # Parents added
# Current object skipped (empty)
Result: ClsCode = "A_B"
```

---

### All Codes Empty

**Scenario:**
```
No parent levels have codes
Current object has no code
```

**Result:**
```powershell
$codeParts = @()  # Nothing added
Result: ClsCode = null
```

---

## Diagnostic Logging

### Enhanced Trace Messages

**mBuildClsCode now logs:**

1. **Current object's code added:**
   ```
   Added current object's ClsLevelCode: M8-BOLT
   ```

2. **Final concatenation:**
   ```
   Built ClsCode from 4 parts: ME_COMP_FAST_M8-BOLT
   ```

**mUpdateClsCode logs:**
```
ClsCode initialized/updated to: ME_COMP_FAST_M8-BOLT
```

**How to Read Logs:**
```
[Trace] Added current object's ClsLevelCode: M8-BOLT
        ↑ Confirms current object's code was found and added

[Trace] Built ClsCode from 4 parts: ME_COMP_FAST_M8-BOLT
        ↑ Shows total parts (3 parents + 1 current = 4)

[Trace] ClsCode initialized/updated to: ME_COMP_FAST_M8-BOLT
        ↑ Final value set to property
```

---

## Testing Checklist

### Basic Functionality
1. ✅ Edit Level 1 object → ClsCode = "L1Code"
2. ✅ Edit Level 2 object → ClsCode = "L1_L2"
3. ✅ Edit Level 3 object → ClsCode = "L1_L2_L3"
4. ✅ Edit Level 4 object → ClsCode = "L1_L2_L3_L4"

### Current Object ClsLevelCode Changes
5. ✅ Change current object's ClsLevelCode → ClsCode updates
6. ✅ Clear current object's ClsLevelCode → Code removed from ClsCode
7. ✅ Set ClsLevelCode before breadcrumb → ClsCode builds when breadcrumb initializes

### Edge Cases
8. ✅ Parent with empty code → Parent skipped in ClsCode
9. ✅ Current object empty code → Only parent codes in ClsCode
10. ✅ All codes empty → ClsCode = null

### Multi-Level Objects
11. ✅ Class Object under Level 4 → ClsCode = "L1_L2_L3_L4_ClassCode"
12. ✅ Term Object → ClsCode includes all levels + term code

---

## Benefits of Corrected Implementation

### Accuracy
- ✅ **Complete Hierarchy:** Full classification path including current object
- ✅ **Consistent Format:** Always uses same delimiter and structure
- ✅ **Unique Codes:** Each object has complete unique classification code

### User Experience
- ✅ **Immediate Display:** ClsCode shows complete path on dialog open
- ✅ **Auto-Sync:** ClsCode updates when user changes ClsLevelCode
- ✅ **No Manual Calculation:** System handles all concatenation

### Data Integrity
- ✅ **Traceable:** ClsCode reveals full object position in hierarchy
- ✅ **Searchable:** Can search for objects by complete or partial ClsCode
- ✅ **Reportable:** ClsCode can be used in reports and queries

---

## Support Information

**Function Modified:** `mBuildClsCode()`  
**Property Added:** Current object's `ClsLevelCode` to concatenation  
**Delimiter:** `_` (underscore)  
**Order:** Parent Level 1 → Level 2 → Level 3 → Level 4 → Current Object

**Example UIString Keys:**
- `Adsk.QS.ClsLevelCode` = "Level Code" (property name)
- `Adsk.QS.ClsCode` = "Classification Code" (concatenated result)

---

**Fix Complete** ✅  
**Version:** 1.3.4  
**User Benefit:** ClsCode now includes complete classification hierarchy including current object's code  
**Date:** April 1, 2026
