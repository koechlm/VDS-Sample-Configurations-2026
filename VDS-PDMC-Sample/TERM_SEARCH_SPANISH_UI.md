# Term Search Expander - Spanish Language Support

## Version
**Version:** 1.4.0  
**Date:** April 1, 2026  
**Feature:** Added Spanish (ES) language support to Term Search UI  
**Files Modified:**
- `ADSK.QS.File.xaml`
- `en-US/UIStrings.xml`
- `de-DE/UIStrings.xml`
**Status:** ✅ COMPLETE

---

## Overview

Extended the Term Search expander (`expTermSearch`) in the File dialog to include Spanish (ES) language support, matching the existing implementation for German (DE), English (EN), French (FR), and Italian (IT).

---

## Changes Made

### 1. UIStrings - Added Spanish Language Label

#### en-US/UIStrings.xml
**Line Added:** 514

```xml
<UIString ID="ClassTerms_05a">Spanish</UIString>
```

**Before:**
```xml
<UIString ID="ClassTerms_05">Italian</UIString>
<UIString ID="ClassTerms_06">No matching term(s) found.</UIString>
```

**After:**
```xml
<UIString ID="ClassTerms_05">Italian</UIString>
<UIString ID="ClassTerms_05a">Spanish</UIString>
<UIString ID="ClassTerms_06">No matching term(s) found.</UIString>
```

---

#### de-DE/UIStrings.xml
**Line Added:** 512

```xml
<UIString ID="ClassTerms_05a">Spanisch</UIString>
```

**Before:**
```xml
<UIString ID="ClassTerms_05">Italienisch</UIString>
<UIString ID="ClassTerms_06">Keine übereinstimmende Begriffe vorhanden.</UIString>
```

**After:**
```xml
<UIString ID="ClassTerms_05">Italienisch</UIString>
<UIString ID="ClassTerms_05a">Spanisch</UIString>
<UIString ID="ClassTerms_06">Keine übereinstimmende Begriffe vorhanden.</UIString>
```

---

### 2. XAML - Languages GroupBox

**Location:** ADSK.QS.File.xaml, Lines 817-830

#### Added 5th Column Definition

**Before:**
```xml
<Grid.ColumnDefinitions>
    <ColumnDefinition/>
    <ColumnDefinition/>
    <ColumnDefinition/>
    <ColumnDefinition/>
</Grid.ColumnDefinitions>
```

**After:**
```xml
<Grid.ColumnDefinitions>
    <ColumnDefinition/>
    <ColumnDefinition/>
    <ColumnDefinition/>
    <ColumnDefinition/>
    <ColumnDefinition/>  <!-- Added 5th column for Spanish -->
</Grid.ColumnDefinitions>
```

---

#### Added chkES CheckBox

**Before:**
```xml
<CheckBox x:Name="chkDE" Content="{Binding UIString[ClassTerms_02], FallbackValue=German}"/>
<CheckBox x:Name="chkEN" Content="{Binding UIString[ClassTerms_03], FallbackValue=English}" Grid.Column="1"/>
<CheckBox x:Name="chkFR" Content="{Binding UIString[ClassTerms_04], FallbackValue=French}" Grid.Column="2"/>
<CheckBox x:Name="chkIT" Content="{Binding UIString[ClassTerms_05], FallbackValue=Italian}" Grid.Column="3"/>
```

**After:**
```xml
<CheckBox x:Name="chkDE" Content="{Binding UIString[ClassTerms_02], FallbackValue=German}"/>
<CheckBox x:Name="chkEN" Content="{Binding UIString[ClassTerms_03], FallbackValue=English}" Grid.Column="1"/>
<CheckBox x:Name="chkFR" Content="{Binding UIString[ClassTerms_04], FallbackValue=French}" Grid.Column="2"/>
<CheckBox x:Name="chkIT" Content="{Binding UIString[ClassTerms_05], FallbackValue=Italian}" Grid.Column="3"/>
<CheckBox x:Name="chkES" Content="{Binding UIString[ClassTerms_05a], FallbackValue=Spanish}" Grid.Column="4"/>
```

**Control Details:**
- **Name:** `chkES`
- **Binding:** `UIString[ClassTerms_05a]`
- **Fallback:** "Spanish"
- **Grid.Column:** 4

---

### 3. XAML - DataGrid Column

**Location:** ADSK.QS.File.xaml, Lines 855-863

#### Added Term_ES Column

**Before:**
```xml
<DataGridTextColumn Binding="{Binding Term_IT}" Width="Auto" MinWidth="140" MaxWidth="200">
    <DataGridTextColumn.HeaderTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding DataContext.UIString[ClassTerms_05], FallbackValue=Italian, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
        </DataTemplate>
    </DataGridTextColumn.HeaderTemplate>
</DataGridTextColumn>
</DataGrid.Columns>
```

**After:**
```xml
<DataGridTextColumn Binding="{Binding Term_IT}" Width="Auto" MinWidth="140" MaxWidth="200">
    <DataGridTextColumn.HeaderTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding DataContext.UIString[ClassTerms_05], FallbackValue=Italian, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
        </DataTemplate>
    </DataGridTextColumn.HeaderTemplate>
</DataGridTextColumn>
<DataGridTextColumn Binding="{Binding Term_ES}" Width="Auto" MinWidth="140" MaxWidth="200">
    <DataGridTextColumn.HeaderTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding DataContext.UIString[ClassTerms_05a], FallbackValue=Spanish, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
        </DataTemplate>
    </DataGridTextColumn.HeaderTemplate>
</DataGridTextColumn>
</DataGrid.Columns>
```

**Column Details:**
- **Binding:** `{Binding Term_ES}` (from CatalogData class)
- **Width:** Auto
- **MinWidth:** 140
- **MaxWidth:** 200
- **Header:** Binds to `UIString[ClassTerms_05a]`

---

## UI Layout

### Languages Filter GroupBox

**Before (4 checkboxes):**
```
┌─────────────────────────────────────────────────┐
│ Additional Languages                            │
├─────────────────────────────────────────────────┤
│  ☐ German   ☐ English   ☐ French   ☐ Italian  │
└─────────────────────────────────────────────────┘
```

**After (5 checkboxes):**
```
┌──────────────────────────────────────────────────────────┐
│ Additional Languages                                     │
├──────────────────────────────────────────────────────────┤
│  ☐ German   ☐ English   ☐ French   ☐ Italian   ☐ Spanish │
└──────────────────────────────────────────────────────────┘
```

---

### Search Results DataGrid

**Before (4 columns):**
```
┌─────────┬─────────┬─────────┬─────────┐
│ German  │ English │ French  │ Italian │
├─────────┼─────────┼─────────┼─────────┤
│ Schraube│ Screw   │ Vis     │ Vite    │
└─────────┴─────────┴─────────┴─────────┘
```

**After (5 columns):**
```
┌─────────┬─────────┬─────────┬─────────┬──────────┐
│ German  │ English │ French  │ Italian │ Spanish  │
├─────────┼─────────┼─────────┼─────────┼──────────┤
│ Schraube│ Screw   │ Vis     │ Vite    │ Tornillo │
└─────────┴─────────┴─────────┴─────────┴──────────┘
```

---

## Data Flow Integration

### PowerShell Module Already Updated

The PowerShell module `ADSK.QS.CustentClassification.psm1` was already updated in version 1.3.1 with:

1. **CatalogData Class:**
   ```powershell
   class CatalogData {
       [string]$Term_DE
       [string]$Term_EN
       [string]$Term_FR
       [string]$Term_IT
       [string]$Term_ES  # Already added
   }
   ```

2. **Search Condition Check:**
   ```powershell
   If ($dsWindow.FindName("chkES").IsChecked -eq $true) { 
       $_NumConds += 1 
   }
   ```

3. **Search Condition Creation:**
   ```powershell
   If ($dsWindow.FindName("chkES").IsChecked -eq $true) {
       $srchConds[$_i] = mCreateClsSearchCond $UIString["ClassTerms_12a"] $mSearchText1 "OR"
       $_i += 1
   }
   ```

4. **Data Row Population:**
   ```powershell
   $row.Term_ES = $props[$UIString["ClassTerms_12a"]]  # Term ES
   ```

**Result:** ✅ PowerShell backend and UI now fully synchronized

---

## UIString Key Mapping

| Language | Checkbox Label Key | Column Header Key | Property Name Key | Value |
|----------|-------------------|-------------------|-------------------|-------|
| German   | ClassTerms_02     | ClassTerms_02     | ClassTerms_09     | "German" / "Deutsch" |
| English  | ClassTerms_03     | ClassTerms_03     | ClassTerms_10     | "English" / "Englisch" |
| French   | ClassTerms_04     | ClassTerms_04     | ClassTerms_11     | "French" / "Französisch" |
| Italian  | ClassTerms_05     | ClassTerms_05     | ClassTerms_12     | "Italian" / "Italienisch" |
| **Spanish** | **ClassTerms_05a** | **ClassTerms_05a** | **ClassTerms_12a** | **"Spanish" / "Spanisch"** |

---

## User Interaction Flow

### Search with Spanish Filter

1. **User opens File Edit dialog**
2. **Clicks "Catalog..." button** → Term search expander opens
3. **Enters search text:** "tornillo"
4. **Checks "Spanish" checkbox** (chkES)
5. **Clicks "Search" button**
6. **PowerShell searches:** Custom entities with Term ES property matching "tornillo"
7. **Results displayed:** DataGrid shows all 5 language columns including Spanish
8. **User selects row**
9. **Clicks "Adopt"**
10. **Properties filled:** Title ES = selected Term_ES value

---

## Testing Checklist

### UI Display Tests
1. ✅ Open File Edit dialog → Verify "Spanish" checkbox visible
2. ✅ Checkbox displays correct label (English: "Spanish", German: "Spanisch")
3. ✅ DataGrid shows 5 columns with Spanish header
4. ✅ Column widths appropriate (MinWidth=140, MaxWidth=200)

### Functionality Tests
5. ✅ Check Spanish checkbox → Search includes Term ES property
6. ✅ Uncheck Spanish checkbox → Search excludes Term ES property
7. ✅ Search results populate Term_ES column correctly
8. ✅ Select term with Spanish → Title ES property populated

### Localization Tests
9. ✅ English UI → Checkbox shows "Spanish", column shows "Spanish"
10. ✅ German UI → Checkbox shows "Spanisch", column shows "Spanisch"

### Data Binding Tests
11. ✅ CatalogData.Term_ES binds to DataGrid column
12. ✅ Empty Term ES values display correctly (blank cell)
13. ✅ Special characters in Spanish terms display correctly (ñ, á, é, í, ó, ú)

---

## Visual Consistency

### Checkbox Alignment
All 5 checkboxes evenly distributed using equal column definitions:
```xml
<Grid.ColumnDefinitions>
    <ColumnDefinition/>  <!-- German -->
    <ColumnDefinition/>  <!-- English -->
    <ColumnDefinition/>  <!-- French -->
    <ColumnDefinition/>  <!-- Italian -->
    <ColumnDefinition/>  <!-- Spanish -->
</Grid.ColumnDefinitions>
```

### DataGrid Column Width
All language columns use identical sizing:
- **Width:** Auto
- **MinWidth:** 140
- **MaxWidth:** 200

This ensures consistent layout regardless of language selected.

---

## Dependencies

### Vault Property Definitions Required
- **Custom Entity Property:** "Term ES" (ClassTerms_12a)
- **File Property:** "Title ES" (for AutoCAD/Inventor)
- **File Property:** "_XLTN_TITLE-ES" (for Vault File context)

### XAML Controls
- ✅ `chkES` - Spanish language filter checkbox
- ✅ `Term_ES` column in `dataGrdTermsFound` DataGrid

### PowerShell Functions
- ✅ `mSearchTerms()` - Already includes chkES check
- ✅ `m_SelectTerm()` - Already includes Term_ES property assignment
- ✅ `CatalogData` class - Already includes Term_ES property

---

## Backward Compatibility

### No Breaking Changes
- ✅ Existing 4 language checkboxes unchanged
- ✅ Existing DataGrid columns unchanged (just added 5th)
- ✅ Existing search logic unchanged (just added ES condition)
- ✅ Users without Term ES data see blank column (graceful degradation)

### Data Migration
- ❌ No migration required
- ❌ No existing data affected
- ✅ Spanish terms can be added incrementally
- ✅ Blank Term ES values handled correctly

---

## Benefits

### User Experience
- ✅ **Comprehensive Search:** Users can search in 5 languages
- ✅ **Spanish-Speaking Users:** Native language support
- ✅ **Multilingual Teams:** Better collaboration across languages
- ✅ **Consistent UI:** Spanish support matches other languages

### Data Management
- ✅ **Complete Localization:** All major European languages covered
- ✅ **Flexible Entry:** Can populate Spanish terms as needed
- ✅ **Search Accuracy:** Filter by specific language improves relevance

---

## Related Enhancements

### Version 1.3.1: PowerShell Spanish Support
- Added Term_ES to CatalogData class
- Added chkES checkbox check in search
- Added Term_ES search condition
- Added Term_ES data population
- Added Title ES property assignments

### Version 1.4.0: UI Spanish Support (This Version)
- Added ClassTerms_05a UIString (Spanish/Spanisch)
- Added 5th column definition in Languages grid
- Added chkES checkbox control
- Added Term_ES DataGrid column

**Result:** Complete end-to-end Spanish language support ✅

---

## Deployment Notes

### Files to Deploy
1. **UIStrings:**
   - `en-US/UIStrings.xml` (ClassTerms_05a = "Spanish")
   - `de-DE/UIStrings.xml` (ClassTerms_05a = "Spanisch")

2. **XAML:**
   - `Vault.Custom/Configuration/ADSK.QS.File.xaml` (chkES checkbox + Term_ES column)

3. **PowerShell (Already Deployed in 1.3.1):**
   - `Vault.Custom/addinVault/ADSK.QS.CustentClassification.psm1`

### Restart Requirements
- ✅ Restart Vault Explorer clients (to reload XAML/UIStrings)
- ❌ No Vault server restart required
- ❌ No CAD application restart required (unless using Term Catalog)

### Vault Configuration
- Create custom entity property: "Term ES" (if not exists)
- Populate Spanish term data in custom entities
- Add "Title ES" file property (if not exists)

---

## Support Information

**Control Names:**
- `chkES` - Spanish language filter checkbox
- `dataGrdTermsFound` - Term search results DataGrid

**UIString Keys:**
- `ClassTerms_05a` - Spanish language label
- `ClassTerms_12a` - Term ES property name

**Data Binding:**
- `Term_ES` - CatalogData class property (PowerShell)
- `{Binding Term_ES}` - DataGrid column binding (XAML)

---

**Enhancement Complete** ✅  
**Version:** 1.4.0  
**User Benefit:** Full Spanish language support in term catalog search  
**Date:** April 1, 2026
