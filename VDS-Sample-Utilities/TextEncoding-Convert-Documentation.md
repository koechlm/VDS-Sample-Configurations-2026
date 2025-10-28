# Documentation: `TextEncoding` and `Convert` Classes for PowerShell Consumption

This document describes the usage of the `TextEncoding` and `Convert` classes in the `VdsSampleUtilities` assembly, specifically for Vault Data Standard PowerShell scripts. Each method is documented with its purpose, parameters, return type, and PowerShell usage.

---

## 1. TextEncoding Class

Provides encoding and decoding methods for strings and byte arrays using UTF8 and ASCII.

### Methods

#### `UTF8GetBytes(string String) : byte[]`
- **Purpose:** Converts a string to a UTF8-encoded byte array.
- **Parameters:**  
  - `String` (`string`): The input string to encode.
- **Returns:**  
  - `byte[]`: UTF8-encoded byte array.
- **PowerShell Usage:**
```powershell
$_TextEncoding = New-Object VdsSampleUtilities.TextEncoding
$bytes = $_TextEncoding.UTF8GetBytes("Hello World")
```

#### `ASCIIGetBytes(string String) : byte[]`
- **Purpose:** Converts a string to an ASCII-encoded byte array.
- **Parameters:**  
  - `String` (`string`): The input string to encode.
- **Returns:**  
  - `byte[]`: ASCII-encoded byte array.
- **PowerShell Usage:**
```powershell
$_TextEncoding = New-Object VdsSampleUtilities.TextEncoding
$bytes = $_TextEncoding.ASCIIGetBytes("Hello World")
```
#### `UTF8GetString(byte[] Bytes) : string`
- **Purpose:** Converts a UTF8-encoded byte array to a string.
- **Parameters:**  
  - `Bytes` (`byte[]`): The UTF8-encoded byte array to decode.
- **Returns:**  
  - `string`: The decoded string.
- **PowerShell Usage:**
```powershell
$_TextEncoding = New-Object VdsSampleUtilities.TextEncoding
$string = $_TextEncoding.UTF8GetString($bytes)
```
#### `ASCIIGetString(byte[] Bytes) : string`
- **Purpose:** Converts an ASCII-encoded byte array to a string.
- **Parameters:**  
  - `Bytes` (`byte[]`): The ASCII-encoded byte array to decode.
- **Returns:**  
  - `string`: The decoded string.
- **PowerShell Usage:**
```powershell
$_TextEncoding = New-Object VdsSampleUtilities.TextEncoding
$string = $_TextEncoding.ASCIIGetString($bytes)
```
---

## 2. Convert Class

Provides conversion methods between strings, numbers, and Base64 encoding.

### Methods

#### `ToInt32(string value) : int`
- **Purpose:** Converts a string to a 32-bit integer.
- **Parameters:**  
  - `value` (`string`): String to convert.
- **Returns:**  
  - `int`: Converted integer.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$intValue = $_Convert.ToInt32("123")
```
#### `Int32ToString(int value) : string`
- **Purpose:** Converts a 32-bit integer to a string.
- **Parameters:**  
  - `value` (`int`): Integer to convert.
- **Returns:**  
  - `string`: Converted string.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$stringValue = $_Convert.Int32ToString(123)
```
#### `ToInt64(string value) : long`
- **Purpose:** Converts a string to a 64-bit integer.
- **Parameters:**  
  - `value` (`string`): String to convert.
- **Returns:**  
  - `long`: Converted long integer.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$longValue = $_Convert.ToInt64("1234567890123456789")
```
#### `Int64ToString(long value) : string`
- **Purpose:** Converts a 64-bit integer to a string.
- **Parameters:**  
  - `value` (`long`): Long integer to convert.
- **Returns:**  
  - `string`: Converted string.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$stringValue = $_Convert.Int64ToString(1234567890123456789)
```
#### `ToDouble(string value) : double`
- **Purpose:** Converts a string to a double.
- **Parameters:**  
  - `value` (`string`): String to convert.
- **Returns:**  
  - `double`: Converted double.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$doubleValue = $_Convert.ToDouble("123.45")
```
#### `DoubleToString(double value) : string`
- **Purpose:** Converts a double to a string.
- **Parameters:**  
  - `value` (`double`): Double to convert.
- **Returns:**  
  - `string`: Converted string.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$stringValue = $_Convert.DoubleToString(123.45)
```
#### `ToBase64String(byte[] byteArray) : string`
- **Purpose:** Converts a byte array to a Base64-encoded string.
- **Parameters:**  
  - `byteArray` (`byte[]`): Byte array to encode.
- **Returns:**  
  - `string`: Base64 string.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$base64String = $_Convert.ToBase64String($byteArray)
```
#### `FromBase64String(string s) : byte[]`
- **Purpose:** Converts a Base64-encoded string to a byte array.
- **Parameters:**  
  - `s` (`string`): Base64 string to decode.
- **Returns:**  
  - `byte[]`: Decoded byte array.
- **PowerShell Usage:**
```powershell
$_Convert = New-Object VdsSampleUtilities.Convert
$byteArray = $_Convert.FromBase64String($base64String)
```

---

## Full PowerShell Sample

```powershell
# Create instances of the classes
$_TextEncoding = New-Object VdsSampleUtilities.TextEncoding
$_Convert = New-Object VdsSampleUtilities.Convert

# Sample text
$text = "Hello World"

# 1. TextEncoding Usage
# Convert text to UTF8 and ASCII byte arrays
$utf8Bytes = $_TextEncoding.UTF8GetBytes($text)
$asciiBytes = $_TextEncoding.ASCIIGetBytes($text)

# Convert byte arrays back to text
$decodedUtf8Text = $_TextEncoding.UTF8GetString($utf8Bytes)
$decodedAsciiText = $_TextEncoding.ASCIIGetString($asciiBytes)

# 2. Convert Usage
# Convert string to Int32, Int64, and Double
$intValue = $_Convert.ToInt32("123")
$longValue = $_Convert.ToInt64("1234567890123456789")
$doubleValue = $_Convert.ToDouble("123.45")

# Convert Int32, Int64, and Double back to string
$intString = $_Convert.Int32ToString($intValue)
$longString = $_Convert.Int64ToString($longValue)
$doubleString = $_Convert.DoubleToString($doubleValue)

# Convert byte array to Base64 string and back
$base64String = $_Convert.ToBase64String($utf8Bytes)
$decodedBytes = $_Convert.FromBase64String($base64String)
```

---

## Notes

- Always ensure the assembly is loaded with `Add-Type -Path ...` before instantiating these classes.
- All methods throw exceptions for invalid input (null or empty).
- These wrappers are designed for environments where direct .NET encoding/conversion is not available in PowerShell.


