# Zen Drift - Proyecto Final de Carrera (Prototipo de Gameplay)

Repositorio correspondiente al desarrollo del proyecto de videojuegos **Zen Drift** para la Tecnicatura en Diseño y Programación de Videojuegos (Universidad Nacional del Litoral, Facultad de Ingeniería y Ciencias Hídricas).

Este espacio contiene el Game Design Document (GDD) del proyecto y el prototipo jugable desarrollado en Godot 4, un roguelite de acción individual que explora el cambio dinámico entre tres afinidades elementales (Agua, Tierra y Fuego/Luz) como mecánica núcleo de combate y supervivencia.

## 📂 Contenido del Repositorio

* `Imagenes de referencia/`: Referencias e inspiraciones que contribuyeron a la visión del gameplay y/o arte.
* `Proyecto/`: Proyecto de Godot 4 con el prototipo jugable (escenas, scripts y recursos).
* `GDD_Zen_Drift_-_Emiliano_Arias.pdf`: Documento principal del Game Design Document (GDD), detallando el high concept, la narrativa, las mecánicas core, el diseño de niveles y la dirección de arte y audio.


## 🎮 Sobre el prototipo

El prototipo se enfoca en validar el *core loop* del GDD (Explorar → Combatir → Recolectar → Adaptarse → Progresar), priorizando la jugabilidad por sobre el arte y el audio finales. Actualmente incluye:

* Movimiento en tercera persona con cámara controlada por mouse/joystick.
* Sistema de 3 afinidades elementales intercambiables (Agua, Tierra, Fuego/Luz), cada una con ataques primario, secundario y especial propios.
* Regla de inmunidad/daño según afinidad activa frente a enemigos elementales.
* Enemigos con IA básica que sueltan energía elemental al ser purificados.
* Contenedores elementales y portal de salida como condición de victoria del nivel.
* Dash, salto y sistema de puntaje según las reglas descritas en el GDD.
* HUD funcional (vida, energía, contenedores, puntaje, afinidad activa).

El arte y el audio son mayormente *placeholders* (formas geométricas y materiales de color plano) mientras se termina de afinar el gameplay.
Ciertos elementos como objetos sólidos, texturas y modelo de personaje los obtuve de tutoriales de gdquest.com, algunos shaders de godotshaders.com y otros efectos de itch.io

## 🛠️ Tecnología

* **Motor:** Godot Engine 4.6.2
* **Lenguaje:** GDScript

## ▶️ Cómo abrir el proyecto

1. Instalar [Godot Engine 4.6.2](https://godotengine.org/) o superior.
2. Abrir Godot → *Importar* → seleccionar la carpeta del repositorio (donde está `project.godot`).
3. Ejecutar la escena principal (`TestLevel.tscn`) para probar el prototipo.

## 👤 Autor

* **Emiliano Arias**
* Estudiante de la Tecnicatura en Diseño y Programación de Videojuegos

## 📌 Estado del Documento

* Versión actual: 0.1.0 (GDD) / Prototipo de gameplay en desarrollo activo
* Fecha de actualización: Agosto 2026
