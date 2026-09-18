# ABYSS
### Game Design Document (GDD) — Nivel 4 (Level Up!)

**Docente:** MIGUEL ANGEL RODRIGUEZ ORTIZ  
**Estudiantes:** 
Juan Carlos Lopez de Cárdenas Avelar
Rogelio Santiago Velasco Pérez
Hiram Morales Moreno
Alfredo Rocha Pizano

**Fecha:** 17 de septiembre de 2026  

---

## 1. High Concept y Perfil del Jugador

**High Concept:** *Umbral Efímero* es un Roguelite de acción 2D (*Twin-stick shooter / Hack & Slash*) de fantasía oscura donde la supervivencia depende de desvíos rítmicos perfectos (Resonancia). Cada muerte destruye el arsenal temporal del jugador, pero le otorga un recurso místico (AURA) para evolucionar sus estadísticas permanentes y conquistar un calabozo implacable. El concepto es claro, original y define una experiencia de tensión y recompensa diferenciada.

**Perfil del Jugador y Estructura:** 
*   **Target:** Jugadores de PC (Intermedio-Avanzado).
*   **Motivación:** *Min-maxing*, dominio técnico y adrenalina pura. 
*   **Justificación:** El perfil del jugador justifica la estructura de alta dificultad y el sistema de control (teclado/ratón) necesario para apuntar en 360 grados mientras se calculan ventanas de invulnerabilidad.

## 2. Core Loop (Bucle de Interacción y Cambio de Estado)

El ciclo de juego es implementable, escalable y gestiona un cambio de estado claro en la sesión del jugador.

1.  **Estado de Vulnerabilidad (Exploración):** El jugador ingresa a una sala. Las puertas se bloquean (*Gating*). La barra de *Esperanza* comienza a drenarse.
2.  **Estado de Tensión (Combate de Resonancia):** El jugador aniquila enemigos mediante reflejos. Los desvíos perfectos (*Parrys*) aturden al enemigo y recargan la *Esperanza*.
3.  **Estado de Recompensa (Saqueo):** Al limpiar la sala, se obtiene *Equipamiento Efímero* (armas para el *run* actual) y *AURA* (moneda permanente).
4.  **Estado de Meta-progresión (Nexo):** Al morir, se pierde el equipo efímero, cambiando el estado del jugador a "Reiniciado", pero se invierte el *AURA* en mejoras permanentes antes del siguiente ciclo.

## 3. Mecánicas, Reglas y Objetivos

Mecánicas, reglas y objetivos están claramente definidos y alineados con la experiencia buscada de riesgo/recompensa.

*   **Mecánica Principal:** *Twin-stick shooting* combinado con un botón dedicado exclusivamente al *Desvío de Resonancia* (Parry dependiente de *frames*).
*   **Reglas de Economía Dual:** El inventario se divide estrictamente en dos. Lo que se usa para atacar (armas) es efímero y se pierde; lo que se usa para mejorar (AURA) es permanente.
*   **Condición de Victoria (Micro):** Despejar la sala actual antes de que la *Esperanza* (tiempo/recurso) o la *Integridad* (salud) lleguen a cero.
*   **Condición de Derrota (Macro):** Perder los 3 puntos de Integridad, lo que resulta en la eliminación inmediata del *run* actual y el retorno al Nexo.

## 4. Narrativa Funcional y Mundo

Narrativa funcional clara que apoya directamente la jugabilidad sin cinemáticas innecesarias.

*   **El Mundo:** Un calabozo hermético que cambia su arquitectura interior.
*   **Justificación Narrativa del Loop:** El jugador es un explorador atado a una maldición de resurrección. El calabozo consume las armas físicas (justificando la pérdida de equipo), pero el alma del explorador absorbe el *AURA* de los caídos. La historia no es decoración; es la base sistémica de la meta-progresión.

## 5. Definición del MVP (Producto Mínimo Viable)

Para garantizar un alcance controlado y evaluar la viabilidad técnica, el MVP se limitará a la comprobación del *Core Loop* en un entorno contenido.

*   **Espacio:** 3 niveles (salas de combate) del mismo sistema, conectadas de forma lineal para el prototipo.
*   **Actores:** 1 personaje controlable (Cubo azul en etapa *gray-box*) y 1 tipo de enemigo cuerpo a cuerpo (Cilindro rojo) con un patrón de ataque telegrafiado de 3 frames de anticipación.
*   **Sistemas activos:** Movimiento, 1 arma básica de disparo, mecánica funcional de *Parry* con feedback visual (destello), recolección de 1 tipo de recurso (*AURA*) y transición de la Sala 1 a la Sala 3.
*   **Condición de término del MVP:** Si el jugador sobrevive la Sala 3, el prototipo lanza una pantalla de "Victoria"; si recibe 3 golpes, lanza "Derrota" y reinicia.

## 6. Sistemas Excluidos del MVP (Fuera de Alcance Inicial)

Como diseñador, asumo la responsabilidad del alcance priorizando la jugabilidad central sobre las características accesorias. Los siguientes sistemas **NO** estarán en el MVP:

*   **Generación Procedimental:** Las 3 salas serán instanciadas y fijas para aislar errores de *gameplay* de errores de generación de niveles.
*   **Jefes (Bosses) y Enemigos a Distancia:** Se postergan para iteraciones posteriores.
*   **Árbol de Habilidades y Nexo:** En el MVP, el *AURA* solo será un contador numérico en pantalla; no habrá tienda funcional.
*   **Inventario Efímero Complejo:** No habrá sistema de rarezas de *Loot* (Gacha) en el prototipo, solo el arma por defecto.

## 7. Interfaz y Experiencia de Juego

*   **HUD:** Minimalista. 3 íconos de salud en la esquina superior izquierda. Barra de *Esperanza* debajo. 
*   **Cámara:** Ortográfica *Top-Down* (cenital), estática por cada sala para no desorientar al jugador durante el combate.
*   **Feedback:** Prioridad absoluta al canal auditivo para confirmar los *Parrys* exitosos, reduciendo la carga visual de la UI.

## 8. Gestión de Riesgos y Alcance Controlado

El GDD asume el rol de diseñador justificando decisiones y previniendo fallas sistémicas estructurales.

1.  **Riesgo de Experiencia (Sobrecarga Cognitiva):** 
    *   *Riesgo:* Apuntar en 360 grados y calcular un *parry* de precisión simultáneamente puede ser injugable.
    *   *Mitigación:* El desvío (*Parry*) será un área de efecto (AoE) omnidireccional alrededor del jugador, no direccional. Esto elimina la necesidad de apuntar el escudo.
2.  **Riesgo Técnico (Colisiones a Alta Velocidad):**
    *   *Riesgo:* En PC, las fluctuaciones de *framerate* pueden provocar que el motor ignore un *hitbox* crítico durante un *dash*.
    *   *Mitigación:* Usar detección de colisiones continua (*Continuous Collision Detection - CCD*) para proyectiles y el jugador.
3.  **Riesgo de Diseño (Efecto Bola de Nieve Negativa):**
    *   *Riesgo:* Si la *Esperanza* se drena demasiado rápido, los jugadores conservadores morirán sin interactuar.
    *   *Mitigación:* La *Esperanza* se detendrá al 1% y no matará directamente al jugador, pero reducirá su velocidad de movimiento drásticamente, obligándolo a pelear para recuperarla.
