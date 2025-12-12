package com.yallaconnect.app.core.util

object PhoneNumberFormatter {
    private const val DEFAULT_COUNTRY_CODE = "1"

    fun digitsOnly(input: String): String = input.filter { it.isDigit() }

    fun canonical(input: String): String {
        var digits = digitsOnly(input)
        if (digits.length == 11 && digits.startsWith(DEFAULT_COUNTRY_CODE)) {
            digits = digits.drop(1)
        }
        return digits
    }

    fun e164(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.startsWith("+")) {
            val clean = trimmed.drop(1).filter { it.isDigit() }
            return if (clean.isBlank()) "" else "+$clean"
        }

        val digits = digitsOnly(trimmed)
        if (digits.isBlank()) return ""
        return when {
            digits.length == 10 -> "+$DEFAULT_COUNTRY_CODE$digits"
            digits.length == 11 && digits.startsWith(DEFAULT_COUNTRY_CODE) -> "+$digits"
            else -> "+$digits"
        }
    }

    fun e164(countryCode: String, phoneNumber: String): String {
        val country = countryCode.filter { it.isDigit() }
        var digits = phoneNumber.filter { it.isDigit() }
        if (digits.startsWith("0")) {
            digits = digits.dropWhile { it == '0' }
        }
        return if (digits.isBlank()) "" else "+$country$digits"
    }

    fun pseudoEmail(input: String): String = "${canonical(input)}@cliqueapp.phone"

    fun numbersMatch(first: String, second: String): Boolean {
        val lhs = canonical(first)
        val rhs = canonical(second)
        if (lhs.isBlank() || rhs.isBlank()) return false
        if (lhs == rhs) return true
        if (lhs.length > rhs.length) return lhs.endsWith(rhs)
        if (rhs.length > lhs.length) return rhs.endsWith(lhs)
        return false
    }
}
