import { defineConfig, globalIgnores } from "eslint/config";
import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
    js.configs.recommended,
    ...nextVitals,
    ...nextTs,

    // Override default ignores of eslint-config-next.
    globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts", "app/generated/**", "backend/dist/**"]),

    {
        plugins: {
            "@stylistic": stylistic
        },
        rules: {
            // 4 пробела (без табов)
            indent: ["error", 4, { SwitchCase: 1 }],
            "no-tabs": "error",

            // двойные кавычки
            quotes: ["error", "double", { avoidEscape: true, allowTemplateLiterals: true }]
        }
    }
]);

export default eslintConfig;
