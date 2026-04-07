# Term Search - Language Display Order Optimization

## Version
**Version:** 1.4.1  
**Date:** April 1, 2026  
**Feature:** Optimized language display order and set English as default  
**File Modified:** `ADSK.QS.File.xaml`  
**Status:** ✅ COMPLETE

---

## Overview

Optimized the Term Search expander to:
1. **Reorder languages** to prioritize English first
2. **Set English as default** (always checked and disabled)
3. **Swap Italian and Spanish** positions for better grouping

---

## Changes Made

### 1. Checkbox Order Changed

**Old Order:**
```
☐ German   ☐ English   ☐ French   ☐ Italian   ☐ Spanish
   (DE)        (EN)        (FR)       (IT)        (ES)
```

**New Order:**
```
☑ English   ☐ German   ☐ French   ☐ Spanish   ☐ Italian
   (EN)        (DE)        (FR)       (ES)        (IT)
```

---

### 2. English Checkbox - Default and Disabled

**XAML Change:**
```xml
<CheckBox x:Name="chkEN" 
          Content="{Binding UIString[ClassTerms_03], FallbackValue=English}" 
          IsChecked="True" 
          IsEnabled="False"/>
```

**Properties:**
- `IsChecked="True"` - Always checked by default
- `IsEnabled="False"` - Grayed out, user cannot uncheck

**Rationale:**
- English is always included in search (baseline language)
- No need for user to toggle it
- Prevents accidental deselection

---

### 3. DataGrid Column Order Changed

**Old Column Order:**
```
│ German │ English │ French │ Italian │ Spanish │
│ Term_DE│ Term_EN │ Term_FR│ Term_IT │ Term_ES │
```

**New Column Order:**
```
│ English │ German │ French │ Spanish │ Italian │
│ Term_EN │ Term_DE│ Term_FR│ Term_ES │ Term_IT │
```

**Benefits:**
- English column first (primary language)
- Spanish before Italian (more commonly used)
- Consistent with checkbox order

---

## Complete XAML Structure

### Checkboxes (Lines 818-832)

```xml
<Grid x:Name="grdLanguages" Margin="0,5,0,0">
    <Grid.ColumnDefinitions>
        <ColumnDefinition/>  <!-- English -->
        <ColumnDefinition/>  <!-- German -->
        <ColumnDefinition/>  <!-- French -->
        <ColumnDefinition/>  <!-- Spanish -->
        <ColumnDefinition/>  <!-- Italian -->
    </Grid.ColumnDefinitions>
    
    <!-- English - Column 0, Checked, Disabled -->
    <CheckBox x:Name="chkEN" 
              Content="{Binding UIString[ClassTerms_03], FallbackValue=English}" 
              IsChecked="True" 
              IsEnabled="False"/>
    
    <!-- German - Column 1 -->
    <CheckBox x:Name="chkDE" 
              Content="{Binding UIString[ClassTerms_02], FallbackValue=German}" 
              Grid.Column="1"/>
    
    <!-- French - Column 2 -->
    <CheckBox x:Name="chkFR" 
              Content="{Binding UIString[ClassTerms_04], FallbackValue=French}" 
              Grid.Column="2"/>
    
    <!-- Spanish - Column 3 -->
    <CheckBox x:Name="chkES" 
              Content="{Binding UIString[ClassTerms_05a], FallbackValue=Spanish}" 
              Grid.Column="3"/>
    
    <!-- Italian - Column 4 -->
    <CheckBox x:Name="chkIT" 
              Content="{Binding UIString[ClassTerms_05], FallbackValue=Italian}" 
              Grid.Column="4"/>
</Grid>
```

---

### DataGrid Columns (Lines 833-872)

```xml
<DataGrid.Columns>
    <!-- Column 1: English (Term_EN) -->
    <DataGridTextColumn Binding="{Binding Term_EN}" Width="Auto" MinWidth="140" MaxWidth="200">
        <DataGridTextColumn.HeaderTemplate>
            <DataTemplate>
                <TextBlock Text="{Binding DataContext.UIString[ClassTerms_03], FallbackValue=English, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
            </DataTemplate>
        </DataGridTextColumn.HeaderTemplate>
    </DataGridTextColumn>
    
    <!-- Column 2: German (Term_DE) -->
    <DataGridTextColumn Binding="{Binding Term_DE}" Width="Auto" MinWidth="140" MaxWidth="200">
        <DataGridTextColumn.HeaderTemplate>
            <DataTemplate>
                <TextBlock Text="{Binding DataContext.UIString[ClassTerms_02], FallbackValue=German, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
            </DataTemplate>
        </DataGridTextColumn.HeaderTemplate>
    </DataGridTextColumn>
    
    <!-- Column 3: French (Term_FR) -->
    <DataGridTextColumn Binding="{Binding Term_FR}" Width="Auto" MinWidth="140" MaxWidth="200">
        <DataGridTextColumn.HeaderTemplate>
            <DataTemplate>
                <TextBlock Text="{Binding DataContext.UIString[ClassTerms_04], FallbackValue=French, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
            </DataTemplate>
        </DataGridTextColumn.HeaderTemplate>
    </DataGridTextColumn>
    
    <!-- Column 4: Spanish (Term_ES) -->
    <DataGridTextColumn Binding="{Binding Term_ES}" Width="Auto" MinWidth="140" MaxWidth="200">
        <DataGridTextColumn.HeaderTemplate>
            <DataTemplate>
                <TextBlock Text="{Binding DataContext.UIString[ClassTerms_05a], FallbackValue=Spanish, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
            </DataTemplate>
        </DataGridTextColumn.HeaderTemplate>
    </DataGridTextColumn>
    
    <!-- Column 5: Italian (Term_IT) -->
    <DataGridTextColumn Binding="{Binding Term_IT}" Width="Auto" MinWidth="140" MaxWidth="200">
        <DataGridTextColumn.HeaderTemplate>
            <DataTemplate>
                <TextBlock Text="{Binding DataContext.UIString[ClassTerms_05], FallbackValue=Italian, RelativeSource={RelativeSource AncestorType={x:Type DataGrid}}}"/>
            </DataTemplate>
        </DataGridTextColumn.HeaderTemplate>
    </DataGridTextColumn>
</DataGrid.Columns>
```

---

## Visual Comparison

### Languages Filter GroupBox

**Before:**
```
┌─────────────────────────────────────────────────────────┐
│ Additional Languages                                    │
├─────────────────────────────────────────────────────────┤
│  ☐ German   ☐ English   ☐ French   ☐ Italian   ☐ Spanish │
└─────────────────────────────────────────────────────────┘
```

**After:**
```
┌─────────────────────────────────────────────────────────┐
│ Additional Languages                                    │
├─────────────────────────────────────────────────────────┤
│  ☑ English   ☐ German   ☐ French   ☐ Spanish   ☐ Italian │
│  (disabled)                                             │
└─────────────────────────────────────────────────────────┘
```

**Visual Indicators:**
- ☑ = Checked (grayed out)
- ☐ = Unchecked (available to check)

---

### Search Results DataGrid

**Before:**
```
┌─────────┬─────────┬─────────┬─────────┬──────────┐
│ German  │ English │ French  │ Italian │ Spanish  │
├─────────┼─────────┼─────────┼─────────┼──────────┤
│ Schraube│ Screw   │ Vis     │ Vite    │ Tornillo │
└─────────┴─────────┴─────────┴─────────┴──────────┘
```

**After:**
```
┌─────────┬─────────┬─────────┬──────────┬─────────┐
│ English │ German  │ French  │ Spanish  │ Italian │
├─────────┼─────────┼─────────┼──────────┼─────────┤
│ Screw   │ Schraube│ Vis     │ Tornillo │ Vite    │
└─────────┴─────────┴─────────┴──────────┴─────────┘
```

---

## User Experience Impact

### Search Behavior

**Default Search (No Optional Languages Selected):**
```
User opens Term Search
→ English checkbox is checked (disabled)
→ German, French, Spanish, Italian unchecked
→ Click "Search"
→ Searches in: Name (main property) + Term EN
```

**With Additional Languages Selected:**
```
User opens Term Search
→ English checkbox is checked (disabled)
→ User checks German and Spanish
→ Click "Search"
→ Searches in: Name + Term EN + Term DE + Term ES
```

**Key Point:** English is ALWAYS included in search, users add other languages as needed.

---

## Rationale for Changes

### 1. English First Position

**Reason:**
- English is the international business language
- Most terminology databases have English as baseline
- Primary language for most Vault installations
- Always searched (disabled checkbox reinforces this)

**User Benefit:**
- English results always visible in first column
- Easier to scan primary language first
- Consistent experience across installations

---

### 2. English Always Checked/Disabled

**Reason:**
- English search is mandatory (coded in PowerShell)
- Prevents user confusion ("Why no results when I unchecked all?")
- Reduces support tickets
- Clear visual indication of default behavior

**Implementation:**
```xml
IsChecked="True"   ← Default state
IsEnabled="False"  ← Cannot be changed
```

**Visual Effect:**
- Checkbox appears grayed out (disabled)
- Checkmark visible but not clickable
- Tooltip (if added) could explain "English is always searched"

---

### 3. Spanish Before Italian

**Reason:**
- Spanish is 2nd most spoken language globally (after Chinese)
- More Spanish-speaking Vault users than Italian
- Spanish-speaking markets larger (Spain, Latin America)
- Better alphabetical grouping: EN, DE, FR, ES, IT

**Geographic Coverage:**
- **Spanish:** Spain, Mexico, Central/South America, parts of USA
- **Italian:** Italy, parts of Switzerland
- Spanish has broader global reach

---

## PowerShell Compatibility

### No Code Changes Required

The PowerShell backend already handles all 5 languages dynamically:

```powershell
# Checkbox checks (order independent)
If ($dsWindow.FindName("chkEN").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkDE").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkFR").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkES").IsChecked -eq $true) { $_NumConds += 1 }
If ($dsWindow.FindName("chkIT").IsChecked -eq $true) { $_NumConds += 1 }
```

**Result:** Display order change is purely UI, no backend impact.

---

## Language Coverage Matrix

| Position | Language | Code | Checkbox | Column Binding | Default State |
|----------|----------|------|----------|----------------|---------------|
| 1st      | English  | EN   | chkEN    | Term_EN        | ☑ Checked (disabled) |
| 2nd      | German   | DE   | chkDE    | Term_DE        | ☐ Unchecked |
| 3rd      | French   | FR   | chkFR    | Term_FR        | ☐ Unchecked |
| 4th      | Spanish  | ES   | chkES    | Term_ES        | ☐ Unchecked |
| 5th      | Italian  | IT   | chkIT    | Term_IT        | ☐ Unchecked |

---

## Control States

### English Checkbox (chkEN)

**Properties:**
```
Name: chkEN
IsChecked: True (always)
IsEnabled: False (grayed out)
Grid.Column: 0 (first position)
```

**Behavior:**
- ✅ Always visible
- ✅ Always checked
- ❌ Cannot be unchecked by user
- ❌ Does not respond to clicks

**Visual Appearance:**
- Gray text (disabled style)
- Checkmark visible but dimmed
- Cursor shows "not allowed" on hover (system default)

---

### Other Language Checkboxes (DE, FR, ES, IT)

**Properties:**
```
IsChecked: False (default)
IsEnabled: True (interactive)
```

**Behavior:**
- ✅ User can check/uncheck
- ✅ Clicking toggles search inclusion
- ✅ Normal enabled appearance

---

## Testing Checklist

### Visual Display Tests
1. ✅ Open File Edit dialog → Term Search expander
2. ✅ Verify checkbox order: EN, DE, FR, ES, IT
3. ✅ Verify English checkbox is checked (grayed out)
4. ✅ Verify other checkboxes are unchecked and enabled
5. ✅ Verify DataGrid column order: English, German, French, Spanish, Italian

### Interaction Tests
6. ✅ Try to uncheck English → Should not respond (disabled)
7. ✅ Check German → Checkbox responds normally
8. ✅ Check Spanish → Checkbox responds normally
9. ✅ Uncheck German → Checkbox responds normally

### Search Functionality Tests
10. ✅ Search with only English (default) → Returns English matches
11. ✅ Check German, search → Returns English + German matches
12. ✅ Check Spanish, search → Returns English + Spanish matches
13. ✅ Check all languages, search → Returns matches from all 5

### Column Order Tests
14. ✅ Search results populate English column first
15. ✅ Verify column headers match checkbox order
16. ✅ Verify data binds correctly to each column

---

## User Documentation Update

### Recommended Help Text

**English Checkbox Tooltip (Optional Addition):**
```xml
<CheckBox x:Name="chkEN" 
          Content="{Binding UIString[ClassTerms_03], FallbackValue=English}" 
          IsChecked="True" 
          IsEnabled="False"
          ToolTip="English is always included in term searches"/>
```

**GroupBox Header (Already Exists):**
```
"Additional Languages" 
```
(Implies English is the base, others are additional)

---

## Benefits Summary

### Usability
- ✅ **Clear Primary Language:** English first reinforces it as baseline
- ✅ **No Mistakes:** Disabled checkbox prevents accidental deselection
- ✅ **Intuitive Layout:** Most important language in first position
- ✅ **Consistent Results:** English always included, predictable behavior

### International Support
- ✅ **English:** Global business language (always available)
- ✅ **German:** Major European market (optional)
- ✅ **French:** European + African markets (optional)
- ✅ **Spanish:** Latin America + Spain (optional, prioritized)
- ✅ **Italian:** Italy market (optional)

### Visual Hierarchy
- ✅ **Primary:** English (Column 0, always visible)
- ✅ **Secondary:** German (Column 1, major EU language)
- ✅ **Tertiary:** French, Spanish, Italian (Columns 2-4, regional)

---

## Migration Notes

### No Breaking Changes
- ✅ All checkbox names unchanged (chkEN, chkDE, chkFR, chkES, chkIT)
- ✅ All column bindings unchanged (Term_EN, Term_DE, etc.)
- ✅ PowerShell script unchanged (reads checkbox state by name)
- ✅ Data structure unchanged (CatalogData class properties same)

### User-Visible Changes
- ✓ Checkbox order different (may surprise users initially)
- ✓ English always checked (cannot be disabled)
- ✓ Column order different (English first)

**Recommendation:** Include note in release notes or training materials

---

## Deployment Checklist

### Files to Deploy
1. ✅ `Vault.Custom/Configuration/ADSK.QS.File.xaml` (modified checkbox order and column order)

### No Changes Required
- ❌ UIStrings.xml (no new strings needed)
- ❌ PowerShell modules (checkbox state handled dynamically)
- ❌ Property definitions (no new properties)

### Testing Before Rollout
1. ✅ Test term search with English only
2. ✅ Test term search with multiple languages
3. ✅ Verify English cannot be unchecked
4. ✅ Verify column order matches checkbox order
5. ✅ Test with different UI languages (EN-US, DE-DE)

---

## Support Information

**Modified Controls:**
- `chkEN` - Now first, checked, disabled
- `chkDE` - Now second position
- `chkFR` - Unchanged position
- `chkES` - Now fourth (before Italian)
- `chkIT` - Now fifth (after Spanish)

**Modified Columns:**
- Term_EN - Now first column
- Term_DE - Now second column
- Term_FR - Unchanged position
- Term_ES - Now fourth column
- Term_IT - Now fifth column

---

**Optimization Complete** ✅  
**Version:** 1.4.1  
**User Benefit:** English prioritized, clearer language hierarchy, better international usability  
**Date:** April 1, 2026
