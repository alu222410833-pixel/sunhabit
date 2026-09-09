# Estructura del proyecto SunHabit

Esta carpeta (`lib/`) contiene todo el código de la aplicación Flutter.

## Organización general

- **`main.dart`** — Punto de entrada de la aplicación.
- **`app.dart`** — Configuración global del `MaterialApp` (tema, rutas, etc.).
- **`core/`** — Funcionalidad compartida y transversal a toda la app.
  - `constants/` — Constantes globales.
  - `navigation/` — Definición de rutas y navegación centralizada.
  - `services/` — Servicios reutilizables (base de datos, notificaciones, etc.).
  - `theme/` — Configuración de colores, tipografía y temas claro/oscuro.
- **`shared/`** — Widgets y utilidades que se usan en varias features.
- **`features/`** — Módulos de la aplicación. Cada feature agrupa su propia UI y lógica.
  - Ejemplo: `features/habits/` contiene todo lo relacionado con hábitos.

## Convención dentro de una feature

Cada feature puede tener subcarpetas según su responsabilidad:

- `data/` — Modelos, repositorios y fuentes de datos.
- `domain/` — Lógica de negocio, casos de uso o entidades (si aplica).
- `presentation/` — Pantallas, widgets y providers/controladores de estado.

Esta estructura ayuda a mantener el código organizado y escalable a medida que crece la app.
