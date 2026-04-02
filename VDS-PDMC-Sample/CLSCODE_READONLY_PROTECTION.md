# ClsCode Read-Only Mode Protection

## Version
**Version:** 1.3.5  
**Date:** April 1, 2026  
**Feature:** Prevent ClsCode updates in read-only mode  
**File Modified:** `ADSK.QS.Default.ps1`  
**Status:** ✅ COMPLETE

---

## Problem Statement

### Issue Discovered During Testing

**Scenario:**
```
User opens Custom Object in read-only mode (view-only)
→ Dialog initializes and calls mUpdateClsCode
→ ClsCode property gets recalculated and updated
→ User sees updated ClsCode value in dialog
→ User clicks OK/Close
→ Changes are NOT saved (read-only mode)
→ Next time user opens: ClsCode shows old value again
```

**Problem:**
- **Misleading UX:** User sees updated ClsCode but it's not persisted
- **Data Confusion:** Displayed value doesn't match actual stored value
- **Wasted Processing:** Calculating value that won't be saved

**User Report:**
> "The ClsCode must not update if the Custom Object is _ReadOnly. The updated value would not save to the object; therefore it is better to even display an outdated value."

---

## Solution

### Approach: Skip ClsCode Updates in Read-Only Mode

**Principle:**
- If object is read-only, don't update ClsCode
- Display whatever value is currently stored (even if outdated)
- User sees accurate representation of what's actually saved in Vault

**Implementation:**
1. Check `_ReadOnly` property before calling `mUpdateClsCode`
2. Add same check to property change event handlers
3. Preserve existing ClsCode value in read-only mode

---

## Code Changes

### Change 1: Edit Mode Initialization

**Location:** Lines 307-313

**Before:**
```powershell
$dsWindow.FindName("cmb_ClsStd").Text = $Prop["_XLTN_CLSSTANDARD"].Value
mAddCoCombo -_CoName $UIString["Adsk.QS.ClsLevel_01"] -_Standard $Prop["_XLTN_CLSSTANDARD"].Value -_classes $_classes

# Update ClsCode based on initialized breadcrumb selections in edit mode
mUpdateClsCode
```

**After:**
```powershell
$dsWindow.FindName("cmb_ClsStd").Text = $Prop["_XLTN_CLSSTANDARD"].Value
mAddCoCombo -_CoName $UIString["Adsk.QS.ClsLevel_01"] -_Standard $Prop["_XLTN_CLSSTANDARD"].Value -_classes $_classes

# Update ClsCode based on initialized breadcrumb selections in edit mode
# Only update if NOT read-only (changes would not save in read-only mode)
if ($Prop["_ReadOnly"].Value -ne $true) {
	mUpdateClsCode
}
```

**Effect:**
- ✅ Read-only mode: ClsCode NOT recalculated, shows stored value
- ✅ Edit mode: ClsCode recalculated and updated normally

---

### Change 2: Property Change Event Handlers

**Location:** Lines 265-273

**Before:**
```powershell
$Prop[$levelProp].add_PropertyChanged({
	param($sender, $e)
	# Update ClsCode when any classification level changes
	if ($dsWindow.FindName("wrpClassification")) {
		mUpdateClsCode
	}
})
```

**After:**
```powershell
$Prop[$levelProp].add_PropertyChanged({
	param($sender, $e)
	# Update ClsCode when any classification level changes
	# Skip update if in read-only mode (changes won't be saved)
	if ($dsWindow.FindName("wrpClassification") -and $Prop["_ReadOnly"].Value -ne $true) {
		mUpdateClsCode
	}
})
```

**Effect:**
- ✅ Read-only mode: PropertyChanged events don't trigger ClsCode update
- ✅ Edit mode: PropertyChanged events trigger updates normally

---

## Behavior Comparison

### Edit Mode (Read/Write Access)

**Execution Flow:**
```
User opens Edit dialog
    ↓
_ReadOnly = false
    ↓
InitializeWindow()
    ↓
mAddCoCombo() - Populates breadcrumb
    ↓
Check: _ReadOnly = false ✓
    ↓
mUpdateClsCode() EXECUTES
    ↓
ClsCode recalculated: "L1_L2_L3_CURRENT"
    ↓
User sees updated ClsCode
    ↓
User clicks OK
    ↓
ClsCode saved to Vault ✓
```

**Result:** ✅ ClsCode updated and saved

---

### Read-Only Mode (View-Only Access)

**Execution Flow:**
```
User opens Edit dialog (view-only)
    ↓
_ReadOnly = true
    ↓
InitializeWindow()
    ↓
mAddCoCombo() - Populates breadcrumb
    ↓
Check: _ReadOnly = true ✗
    ↓
mUpdateClsCode() SKIPPED
    ↓
ClsCode unchanged: Shows stored value (may be outdated)
    ↓
User sees actual stored ClsCode
    ↓
User clicks Close
    ↓
No changes attempted ✓
```

**Result:** ✅ ClsCode preserved as-is (accurate to database)

---

## Example Scenarios

### Scenario 1: Outdated ClsCode in Database

**Stored Data:**
```
Object in Vault:
- ClsLevel_01 = "Mechanical"
- ClsLevel_02 = "Components"
- ClsLevel_03 = "Fasteners"
- ClsLevelCode = "BOLT"
- ClsCode = "ME_COMP"  ← OUTDATED (missing FAST_BOLT)
```

**User Opens in Edit Mode:**
```
_ReadOnly = false
→ mUpdateClsCode() runs
→ ClsCode recalculated = "ME_COMP_FAST_BOLT"
→ User sees: "ME_COMP_FAST_BOLT" ✓
→ User clicks OK → Saves corrected value
```

**User Opens in Read-Only Mode:**
```
_ReadOnly = true
→ mUpdateClsCode() SKIPPED
→ ClsCode unchanged = "ME_COMP"  ← Shows actual stored value
→ User sees: "ME_COMP" (outdated but accurate to DB)
→ User can't edit anyway, so no confusion
```

**Why This Is Better:**
- ✅ Read-only mode shows **truthful** data (what's actually saved)
- ✅ User isn't misled into thinking ClsCode is different than stored
- ✅ If user wants to fix it, they need edit permissions

---

### Scenario 2: User Changes ClsLevelCode (Read-Only)

**User Action:**
```
User in read-only mode sees ClsLevelCode field
User tries to type new value (if somehow enabled)
```

**OLD Behavior (Before Fix):**
```
PropertyChanged event fires
→ mUpdateClsCode() runs
→ ClsCode changes in dialog
→ User thinks it's saved
→ User closes dialog
→ Nothing saved (read-only)
→ User confused: "Why didn't it save?"
```

**NEW Behavior (After Fix):**
```
PropertyChanged event fires
→ Check: _ReadOnly = true ✗
→ mUpdateClsCode() SKIPPED
→ ClsCode unchanged in dialog
→ User sees no change
→ Clear indication that editing is disabled
```

---

### Scenario 3: Classification Hierarchy Change (Read-Only)

**Scenario:**
```
Object's parent levels were renamed in Vault
User opens object in read-only mode
Breadcrumb shows new parent names
ClsCode shows old codes
```

**Behavior:**
```
_ReadOnly = true
→ Breadcrumb populated with current parent data
→ ClsCode NOT recalculated
→ ClsCode shows: Old codes (from when last saved)
→ Visual mismatch between breadcrumb and ClsCode

This is CORRECT because:
- ClsCode reflects actual stored value
- User can't change it anyway (read-only)
- User with edit permissions can open and save to update
```

---

## Permission Scenarios

### Read-Only Triggers

**When is _ReadOnly = true?**

1. **Vault Permissions:**
   - User has View-only access to custom object
   - Object is checked out by another user
   - Object is in lifecycle state preventing edits

2. **Security Roles:**
   - User's role doesn't have Edit permission
   - Object category restricted for user's role

3. **Lifecycle State:**
   - Object in Released/Frozen state
   - State definition prevents property edits

**Check in Dialog Title:**
```powershell
if ($Prop["_ReadOnly"].Value -eq $true) {
	$dsWindow.Title = "Edit ... - [READ ONLY]"  ← User sees indicator
}
```

---

## Benefits

### User Experience
- ✅ **Honest Display:** Shows actual stored value, not calculated value
- ✅ **No False Expectations:** User doesn't see updates that won't save
- ✅ **Clear Read-Only State:** Unchanged values reinforce read-only mode

### Data Integrity
- ✅ **Accurate Representation:** ClsCode matches what's in database
- ✅ **No Phantom Changes:** Avoids showing changes that don't persist
- ✅ **Audit Trail Clarity:** Stored value unchanged = no change confusion

### Performance
- ✅ **Reduced Processing:** Skips unnecessary calculation in view mode
- ✅ **Faster Dialog Load:** One less function call during initialization
- ✅ **No Vault API Calls:** Doesn't fetch level properties if not needed

---

## Edge Cases

### Case 1: Permission Change During Session

**Scenario:**
```
User opens object in read-only mode
Administrator grants edit permission
User still in same dialog session
```

**Behavior:**
```
_ReadOnly value set at dialog initialization
Doesn't change during session
ClsCode updates still skipped
User must close and reopen to get edit mode
```

**Correct:** Dialog permissions are session-based

---

### Case 2: ClsLevelCode Editable in Read-Only

**Scenario:**
```
Object is read-only
But ClsLevelCode field is somehow editable (configuration error)
User changes ClsLevelCode value
```

**Behavior:**
```
PropertyChanged fires
→ Check: _ReadOnly = true
→ mUpdateClsCode SKIPPED
→ ClsCode doesn't update
→ User sees mismatch: ClsLevelCode changed, ClsCode didn't
→ Clicks OK
→ Nothing saves (read-only)
→ Next open: ClsLevelCode reverted too
```

**Expected:** Field should be disabled in read-only mode (XAML config)

---

### Case 3: Partial Read-Only (Some Properties Editable)

**Scenario:**
```
Advanced configuration allows some properties editable in read-only
ClsLevelCode is editable
Other classification properties are not
```

**Recommendation:**
```
Don't update ClsCode even if some properties editable
Reason: ClsCode depends on ALL classification properties
If any are read-only, ClsCode calculation may be incorrect
Better to require full edit mode for ClsCode updates
```

**Current Implementation:** ✅ Skips update if _ReadOnly = true (any read-only)

---

## Testing Checklist

### Read-Only Mode Tests
1. ✅ Open object in read-only mode → ClsCode NOT recalculated
2. ✅ ClsCode shows stored value (even if outdated)
3. ✅ Change property in read-only (if possible) → ClsCode NOT updated
4. ✅ Close dialog → No changes saved
5. ✅ Reopen → ClsCode still shows same stored value

### Edit Mode Tests
6. ✅ Open object in edit mode → ClsCode recalculated
7. ✅ ClsCode shows current calculated value
8. ✅ Change ClsLevelCode → ClsCode updates
9. ✅ Save → ClsCode saved to Vault
10. ✅ Reopen in read-only → Shows saved ClsCode

### Permission Boundary Tests
11. ✅ User without edit permission → _ReadOnly = true, ClsCode not updated
12. ✅ User with edit permission → _ReadOnly = false, ClsCode updated
13. ✅ Object checked out by other user → _ReadOnly = true
14. ✅ Object in lifecycle preventing edits → _ReadOnly = true

---

## Diagnostic Logging

### Updated Log Messages

**Read-Only Mode (ClsCode Update Skipped):**
```
No log message from mUpdateClsCode
(function not called)
```

**Edit Mode (ClsCode Update Executed):**
```
[Trace] Built ClsCode from 4 parts: ME_COMP_FAST_BOLT
[Trace] ClsCode initialized/updated to: ME_COMP_FAST_BOLT
```

**How to Verify Read-Only Skip:**
```
Search logs for "ClsCode initialized/updated to:"
If NOT found → mUpdateClsCode was skipped (likely read-only)
If found → mUpdateClsCode executed (edit mode)
```

---

## Related Changes

### No Changes Required In:
- ✅ `mBuildClsCode()` - Function logic unchanged
- ✅ `mUpdateClsCode()` - Function logic unchanged
- ✅ `mCoComboSelectionChanged()` - Still updates ClsCode on user selection
- ✅ Property definitions - No new properties needed

### Why Combo Selection Still Works:
```powershell
function mCoComboSelectionChanged ($sender) {
	# ... selection logic ...
	
	# This ALWAYS updates ClsCode
	$concatenatedCode = mBuildClsCode $mBreadCrumb $Global:_BreadcrumbLevelMaps
	$Prop[$UIString["Adsk.QS.ClsCode"]].Value = $concatenatedCode
}
```

**Note:** Combo selection changes should be disabled in read-only mode by XAML configuration (IsEnabled="false"). If user somehow changes selection, ClsCode will update in dialog but won't save.

---

## Recommendations

### XAML Configuration

**Ensure proper read-only controls:**
```xml
<!-- Breadcrumb wrapper should be disabled in read-only mode -->
<WrapPanel Name="wrpClassification" 
           IsEnabled="{Binding ElementName=_ReadOnly, Path=Value, Converter={StaticResource BoolInvertConverter}}" />

<!-- ClsLevelCode field should be read-only -->
<TextBox DataContext="{Binding ElementName=ClsLevelCode}" 
         IsReadOnly="{Binding ElementName=_ReadOnly, Path=Value}" />

<!-- ClsCode field should always be read-only (calculated field) -->
<TextBox DataContext="{Binding ElementName=ClsCode}" 
         IsReadOnly="True" />
```

---

## Support Information

**Files Modified:** `ADSK.QS.Default.ps1`  
**Functions Modified:** None (only calling code)  
**Property Checked:** `_ReadOnly` (system property)  
**Behavior:** Skip ClsCode updates when `_ReadOnly = true`

---

**Fix Complete** ✅  
**Version:** 1.3.5  
**User Benefit:** Accurate ClsCode display in read-only mode, no misleading updates  
**Date:** April 1, 2026
