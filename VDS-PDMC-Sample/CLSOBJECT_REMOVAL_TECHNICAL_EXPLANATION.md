# CLSOBJECT Property Removal - Technical Deep Dive

## The Core Issue Explained

### What is CLSOBJECT?
- **Internal Name:** `CLSOBJECT`
- **Display Name:** "Class" (EN) / "Klasse" (DE)
- **Entity:** FILE (not Custom Entity)
- **Purpose:** Stores the name of the assigned Class Object or Term
- **Backing Property:** `$Prop["_XLTN_CLSOBJECT"].Value`

### Why Was It Not Being Removed?

#### The Confusion
The classification system deals with **two types of properties**:

1. **Custom Entity Properties** (stored on Class Object or Term):
   - Code
   - Title
   - Description
   - Term ES
   - Title ES
   - etc.

2. **FILE Entity Properties** (stored on the File itself):
   - **Class (CLSOBJECT)** ← This was the problem!

#### The Incorrect Assumption
We initially thought:
> "If I use `mGetAllClsPrpNames()` to get ALL properties from the Class Object, including those normally filtered out, then 'Class' will be included and removed."

**Why This Failed:**
- `mGetAllClsPrpNames()` calls `GetPropertiesByEntityIds("CUSTENT", @($ClassId))`
- This returns properties stored ON the Custom Entity (Class Object or Term)
- The "Class" property (CLSOBJECT) is NOT stored on the Custom Entity
- It's stored on the FILE entity
- Therefore, it never appears in the results from `mGetAllClsPrpNames()`

### The Correct Understanding

```
┌─────────────────────────────────────────────────────────────┐
│                    VAULT PROPERTY SYSTEM                     │
└─────────────────────────────────────────────────────────────┘

Custom Entity (Class Object or Term)          FILE Entity
┌────────────────────────────┐          ┌───────────────────────┐
│  Properties ON the Object  │          │  Properties ON File   │
│  ─────────────────────────│          │  ──────────────────── │
│  • Code                    │──COPY──▶│  • Code (copied)      │
│  • Title                   │──COPY──▶│  • Title (copied)     │
│  • Description             │──COPY──▶│  • Description        │
│  • Term ES                 │──COPY──▶│  • Term ES (copied)   │
│  • Level 1                 │   ✗    │                        │
│  • Level 2                 │   ✗    │  PLUS:                 │
│  • Standard                │   ✗    │  ──────────────────    │
│  • ...                     │          │  • Class (CLSOBJECT)  │← UNIQUE TO FILE!
│                            │          │    Value = "Mech..."   │
└────────────────────────────┘          └───────────────────────┘

                                        The "Class" property exists
                                        ONLY on the FILE, not on
                                        the Custom Entity!
```

### Why Explicit Removal is Required

**During Assignment:**
```powershell
# Step 1: Get properties from Custom Entity
$mPropsAdd = (Code.Id, Title.Id, Description.Id, ...)

# Step 2: Add CLSOBJECT from FILE property definitions
$mPropsAdd += CLSOBJECT.Id

# Step 3: Apply to file
UpdateFilePropertyDefinitions($mPropsAdd, [], ...)
```

**During Removal (BEFORE FIX):**
```powershell
# Step 1: Get properties from Custom Entity
$mPropsRemove = (Code.Id, Title.Id, Description.Id, ...)

# Step 2: MISSING - CLSOBJECT not in Custom Entity properties!

# Step 3: Remove from file
UpdateFilePropertyDefinitions([], $mPropsRemove, ...)
# Result: Custom Entity properties removed, CLSOBJECT remains! ❌
```

**During Removal (AFTER FIX):**
```powershell
# Step 1: Get properties from Custom Entity
$mPropsRemove = (Code.Id, Title.Id, Description.Id, ...)

# Step 2: [NEW] Explicitly get CLSOBJECT from FILE property definitions
$mFilePropDefs = GetPropertyDefinitionsByEntityClassId("FILE")
$mClassPropertyDef = $mFilePropDefs | Where { $_.SysName -eq "CLSOBJECT" }
$mPropsRemove += $mClassPropertyDef.Id

# Step 3: [NEW] Clear the _XLTN_CLSOBJECT value
$Prop["_XLTN_CLSOBJECT"].Value = ""

# Step 4: Remove from file
UpdateFilePropertyDefinitions([], $mPropsRemove, ...)
# Result: Custom Entity properties AND CLSOBJECT removed! ✅
```

---

## Code Implementation Breakdown

### The Key Code Block

```powershell
# EXPLICIT REMOVAL OF "Class" PROPERTY (CLSOBJECT)
# The "Class" property is added to the FILE to store the assigned class/term name.
# This property must ALWAYS be explicitly removed from the file, regardless of Class Object or Term.
# We need to: 1) Add CLSOBJECT to removal list, 2) Clear the _XLTN_CLSOBJECT value
try {
    # Get ALL property definitions for FILE entities
    $mFilePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
    
    # Find the "Class" property by DispName using UIString (language-aware)
    # IMPORTANT: Uses Adsk.QS.Classification_00 ("Class"), NOT Adsk.QS.ClsObject ("Class Object")
    $mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
    
    if ($mClassPropertyDef) {
        # Only add if not already in the removal list (defensive programming)
        if ($mPropsRemove -notcontains $mClassPropertyDef.Id) {
            $mPropsRemove += $mClassPropertyDef.Id
            $dsDiag.Trace("  [EXPLICIT] Removing 'Class' property (CLSOBJECT) - ID: $($mClassPropertyDef.Id), Display Name: $($mClassPropertyDef.DispName)")
        }
        else {
            $dsDiag.Trace("  [INFO] 'Class' property (CLSOBJECT) already in removal list - ID: $($mClassPropertyDef.Id)")
        }
        
        # CRITICAL: Clear the _XLTN_CLSOBJECT value
        # This ensures the file gets unclassified even if the property relates to file category and doesn't get removed
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

### Why Each Line Matters

1. **`GetPropertyDefinitionsByEntityClassId("FILE")`**
   - Gets property definitions for FILE entities (not Custom Entities)
   - Returns: All possible properties that can exist on files
   - Includes: System properties, UDP definitions, and CLSOBJECT

2. **`Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }`** ⭐ CRITICAL!
   - Uses **DispName** lookup, NOT SysName
   - **UIString Key:** `Adsk.QS.Classification_00` = "Class" (EN) / "Klasse" (DE)
   - **Why not SysName?** FILE property DispName differs from PropertyTranslations mapping
   - **Why not Adsk.QS.ClsObject?** That's for Custom Entity ("Class Object"), not FILE property ("Class")
   - Language-aware: Works in EN-US ("Class"), DE-DE ("Klasse"), and other locales

3. **`if ($mPropsRemove -notcontains $mClassPropertyDef.Id)`**
   - Defensive check to avoid duplicates
   - In theory, CLSOBJECT should never be in Custom Entity properties
   - In practice, protects against edge cases or future changes

4. **`$Prop["_XLTN_CLSOBJECT"].Value = ""`** ⭐ CRITICAL!
   - Clears the translated property value
   - The _XLTN_ prefix is a Data Standard framework convention for translated property access
   - Without clearing this, the property value may persist even if the definition is removed
   - Ensures file is unclassified even if property relates to file category and can't be removed

5. **Error Handling**
   - Logs but doesn't fail if property not found
   - Allows removal to continue for other properties
   - Critical for backward compatibility

---

## Critical Discovery: Display Name Mismatch

### The Naming Confusion

There are **TWO different things** both called "Class" but with different display names:

#### 1. Custom Entity: "Class Object"
```xml
<!-- UIStrings.xml -->
<UIString ID="Adsk.QS.ClsObject">Class Object</UIString>
```
- **Context:** Custom entity type in Vault (CUSTENT)
- **DispName:** "Class Object"
- **Purpose:** Represents a classification object in the hierarchy
- **Used for:** Custom entity definition lookup

#### 2. FILE Property: "Class"
```xml
<!-- UIStrings.xml -->
<UIString ID="Adsk.QS.Classification_00">Class</UIString>
```
- **Context:** Property on FILE entities
- **DispName:** "Class" (EN) / "Klasse" (DE)
- **SysName:** CLSOBJECT (but not used for FILE property lookup!)
- **Purpose:** Stores the name of the assigned class/term on the file
- **Used for:** Property value display on files

### Why SysName Lookup Failed

**Initial Attempt (FAILED):**
```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.SysName -eq "CLSOBJECT" }
```
- **Why it failed:** FILE property definitions may not have SysName populated
- **Result:** `$mClassPropertyDef` was `$null`, property not removed

**Corrected Approach (WORKS):**
```powershell
$mClassPropertyDef = $mFilePropDefs | Where-Object { $_.DispName -eq $UIString["Adsk.QS.Classification_00"] }
```
- **Why it works:** Uses DispName which is always populated
- **Language-aware:** `$UIString["Adsk.QS.Classification_00"]` returns "Class" (EN) or "Klasse" (DE)
- **Result:** Property found and removed successfully ✅

### PropertyTranslations.xml vs UIStrings.xml

**PropertyTranslations.xml:**
```xml
<PropertyTranslation Name="CLSOBJECT">Class</PropertyTranslation>
```
- Maps SysName → DispName for **Custom Entity properties**
- Used when copying properties FROM Class Objects/Terms TO files

**UIStrings.xml:**
```xml
<UIString ID="Adsk.QS.Classification_00">Class</UIString>
```
- Provides localized strings for **UI and FILE property lookups**
- Used when finding properties ON files

### The _XLTN_ Translation System

### What is _XLTN_?
The Data Standard framework provides translated property access using the `_XLTN_` prefix:
- **Real Property Name:** `CLSOBJECT` (stored in Vault database)
- **Translated Access:** `$Prop["_XLTN_CLSOBJECT"]` (used in PowerShell scripts)
- **Purpose:** Provides language-independent property access with automatic translation

### How It Works

```powershell
# When you access a property with _XLTN_ prefix:
$Prop["_XLTN_CLSOBJECT"].Value = "Mechanical Components"

# The framework:
1. Looks up "CLSOBJECT" in PropertyTranslations.xml
2. Gets translated display name ("Class" in EN, "Klasse" in DE)
3. Maps to the actual Vault property by SysName "CLSOBJECT"
4. Sets the value in Vault
```

### Why Both Steps Are Needed

**Step 1: Add property ID to removal list**
```powershell
$mPropsRemove += $mClassPropertyDef.Id
```
- Tells Vault API which property DEFINITION to remove from the file
- Uses the property definition ID from FILE property definitions

**Step 2: Clear the _XLTN_ value**
```powershell
$Prop["_XLTN_CLSOBJECT"].Value = ""
```
- Clears the property VALUE in the Data Standard framework's property dictionary
- Without this, the framework may restore the value when saving
- This is the CRITICAL step that was missing

### Common _XLTN_ Properties in Classification System
| Real Property Name | _XLTN_ Access | Display Name (EN) |
|--------------------|---------------|-------------------|
| `CLSOBJECT` | `$Prop["_XLTN_CLSOBJECT"]` | Class |
| `CLSSTANDARD` | `$Prop["_XLTN_CLSSTANDARD"]` | Standard |
| `CLSLEVEL1` | `$Prop["_XLTN_CLSLEVEL1"]` | Level 1 |
| `CLSLEVEL2` | `$Prop["_XLTN_CLSLEVEL2"]` | Level 2 |
| `CLSLEVEL3` | `$Prop["_XLTN_CLSLEVEL3"]` | Level 3 |
| `CLSLEVEL4` | `$Prop["_XLTN_CLSLEVEL4"]` | Level 4 |

---

## Common Misconceptions Addressed

### ❌ Misconception 1: "Class property comes from Class Object"
**Reality:** The "Class" property is a FILE property that REFERENCES the Class Object name, but doesn't come FROM the Class Object.

### ❌ Misconception 2: "mGetAllClsPrpNames() returns ALL properties including Class"
**Reality:** `mGetAllClsPrpNames()` only returns properties stored ON the Custom Entity. CLSOBJECT is stored on the FILE.

### ❌ Misconception 3: "This only affects Uniclass Terms"
**Reality:** This affects ALL standards and ALL classification types (Class Objects and Terms). The bug was universal.

### ❌ Misconception 4: "We should check if Standard = 'Uniclass' before removing"
**Reality:** CLSOBJECT exists for ALL classifications regardless of standard. It should ALWAYS be removed.

---

## Entity Type Comparison

### Custom Entity Properties (CUSTENT)
```powershell
# Retrieved via PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))
# Returns properties stored ON the Custom Entity

Example for Class Object "Mechanical Components":
- Code = "MECH-001"
- Title = "Mechanical Components"
- Description = "Components for mechanical assemblies"
- Level 1 = "Engineering"
- Level 2 = "Mechanical"
- Standard = "IEC 61355"
- Term ES = "" (empty for non-Terms)
```

### FILE Entity Properties (FILE)
```powershell
# Retrieved via PropertyService.GetPropertiesByEntityIds("FILE", @($FileId))
# Returns properties stored ON the File

Example for file with classification:
- _FileName = "Assembly.iam"
- _RevisionLabel = "A"
- Code = "MECH-001" (copied from Custom Entity)
- Title = "Mechanical Components" (copied from Custom Entity)
- Description = "..." (copied from Custom Entity)
- Class (CLSOBJECT) = "Mechanical Components" (UNIQUE to FILE!)
```

### Property Definition Comparison

| Aspect | Custom Entity Properties | FILE Property (CLSOBJECT) |
|--------|-------------------------|---------------------------|
| **Source** | Stored on Custom Entity | Stored on FILE |
| **Retrieval** | `GetPropertiesByEntityIds("CUSTENT", ...)` | `GetPropertyDefinitionsByEntityClassId("FILE")` |
| **Purpose** | Hold classification metadata | Track which class/term assigned |
| **During Assignment** | Copied TO file | Added TO file |
| **During Removal** | IDs removed from file | Must be explicitly removed |
| **Example** | Code, Title, Description | Class (CLSOBJECT) |

---

## API Call Differences

### Getting Custom Entity Properties
```powershell
# Returns property INSTANCES on a specific Custom Entity
$vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($ClassId))

# Result: Array of PropInst objects
# Each PropInst has:
#   - PropDefId (the property definition ID)
#   - Val (the value for this specific Custom Entity)
#   - Example: { PropDefId: 123, Val: "MECH-001" }
```

### Getting FILE Property Definitions
```powershell
# Returns property DEFINITIONS for FILE entities
$vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")

# Result: Array of PropDef objects
# Each PropDef has:
#   - Id (the property definition ID)
#   - SysName (internal name, e.g., "CLSOBJECT")
#   - DispName (display name, e.g., "Class")
#   - Example: { Id: 999, SysName: "CLSOBJECT", DispName: "Class" }
```

### Key Difference
- **GetPropertiesByEntityIds:** Returns values for a SPECIFIC entity instance
- **GetPropertyDefinitionsByEntityClassId:** Returns definitions for an entity CLASS (all possible properties)

---

## Why This Wasn't Caught Earlier

1. **Visual Confusion:** In Vault UI, all properties appear together, making it hard to distinguish their source
2. **Partial Success:** Properties from Custom Entity WERE being removed, masking the issue
3. **Limited Testing:** Most testing focused on assignment, not thorough removal verification
4. **Standard Variations:** Bug affected all standards equally, so no comparative testing revealed it
5. **Property Name Similarity:** "Class" seemed like it should come from "Class Object", creating false assumption

---

## Verification Commands

### Check if CLSOBJECT is on a File
```powershell
# In Vault context
$Prop["_XLTN_CLSOBJECT"].Value  # Should show class/term name if assigned, empty if not

# Via API
$fileProps = $vault.PropertyService.GetPropertiesByEntityIds("FILE", @($fileId))
$clsObjProp = $fileProps | Where-Object { $_.PropDefId -eq $clsObjectPropDefId }
```

### Check if CLSOBJECT is on a Custom Entity
```powershell
# This will NEVER find it - CLSOBJECT doesn't exist on Custom Entities!
$custentProps = $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT", @($classId))
$clsObjProp = $custentProps | Where-Object { $_.SysName -eq "CLSOBJECT" }  # Will be $null
```

### Get FILE Property Definitions
```powershell
$filePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
$clsObjectDef = $filePropDefs | Where-Object { $_.SysName -eq "CLSOBJECT" }

Write-Host "CLSOBJECT Definition:"
Write-Host "  Id: $($clsObjectDef.Id)"
Write-Host "  SysName: $($clsObjectDef.SysName)"
Write-Host "  DispName: $($clsObjectDef.DispName)"
```

---

## Lessons Learned

1. **Entity Boundaries:** Always verify which entity (CUSTENT vs FILE) a property belongs to
2. **API Documentation:** GetPropertiesByEntityIds vs GetPropertyDefinitionsByEntityClassId serve different purposes
3. **Explicit is Better:** When dealing with cross-entity relationships, explicit lookups are safer than assumptions
4. **Complete Testing:** Test full lifecycle (assign AND remove) for all scenarios
5. **Defensive Programming:** Check for duplicates and handle missing properties gracefully

---

## Related Documentation
- `UNICLASS_CLASS_PROPERTY_REMOVAL.md` - Main implementation guide
- `COMPLETE_CHANGES_SUMMARY.md` - Version history
- `QUICK_REFERENCE.md` - Testing quick reference

---

**Technical Level:** Expert  
**Audience:** Developers debugging or extending classification system  
**Last Updated:** March 29, 2026
