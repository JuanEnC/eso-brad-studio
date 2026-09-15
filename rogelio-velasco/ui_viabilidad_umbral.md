# UI, dinámicas y viabilidad de *Umbral: Ciclo de la Ciudad Viva*

**Rogelio Santiago Velasco Pérez**

## Objetivo de la interfaz

La interfaz de *Umbral* debe ayudar al jugador a tomar decisiones rápidas sin distraerlo del combate. Como el juego se basa en leer animaciones, desviar ataques y administrar la Frecuencia, la mayor parte de la información se comunica cerca del personaje o del enemigo. El HUD solo conserva los datos que el jugador necesita consultar de forma constante.

El principio es sencillo: durante el combate, la pantalla explica **qué está en riesgo y qué acción salió bien o mal**. Fuera del combate, explica **qué decisión puede tomar el jugador y qué consecuencia tiene**.

## Concepto de UI: HUD, canales de información y feedback

### HUD permanente

- **Integridad de Nara:** tres segmentos en la esquina inferior izquierda. Indican cuántos errores importantes puede cometer el jugador antes de terminar la expedición.
- **Frecuencia de Nara:** un arco alrededor de la Integridad. Cambia gradualmente de azul tenue a naranja y rojo cuando está cerca de saturarse. No muestra un número; importa reconocer el peligro de forma inmediata.
- **Objetivo de la expedición:** un indicador pequeño en la parte superior que muestra el distrito actual y la dirección del siguiente punto importante. No se usa un minimapa completo para no resolver la exploración automáticamente.
- **Ecos activos:** tres iconos pequeños debajo de la Integridad. Solo muestran el efecto esencial de cada Eco y se pueden consultar con detalle entre salas.

### Información asociada al enemigo y al entorno

- **Frecuencia enemiga:** aparece como una barra breve debajo del enemigo solo cuando Nara lo fija o está cerca de él. Al llenarse, comunica que ya se puede realizar una Ruptura.
- **Señales de ataque:** las animaciones preparatorias son la fuente principal. Los ataques peligrosos tienen además un destello corto de color y un sonido específico; no se colocan iconos sobre todos los enemigos de manera permanente.
- **Campos de Frecuencia:** se ven en el escenario como zonas con pulsos de luz y sonido ambiental. La interfaz solo los refuerza cuando están afectando a Nara.

### Canales de feedback

| Canal | Información que comunica | Ejemplo |
|---|---|---|
| Visual | Resultado de la acción y estado de Frecuencia. | Chispas azules en un desvío preciso; arco rojo cuando Nara está por saturarse. |
| Sonoro | Precisión del tiempo y riesgo inmediato. | Golpe metálico limpio al desviar bien; sonido más apagado si el bloqueo fue tardío. |
| Háptico (control) | Impacto y confirmación breve. | Vibración corta en un desvío correcto y vibración más fuerte cuando Nara recibe daño. |
| Cámara | Consecuencia física sin perder legibilidad. | Pausa visual muy breve al ejecutar una Ruptura; no hay sacudidas largas durante ataques normales. |

## Loop principal de interacción

1. **Entrar a una sala:** el jugador identifica la forma del espacio, las rutas disponibles y el tipo de amenaza.
2. **Leer:** observa la animación, distancia y ritmo del enemigo.
3. **Responder:** ataca, se desplaza o desvía según la señal recibida.
4. **Confirmar:** la interfaz y el feedback muestran si aumentó la Frecuencia del enemigo o la de Nara.
5. **Romper:** cuando la Frecuencia enemiga se llena, el jugador ejecuta una Ruptura.
6. **Elegir:** al limpiar la sala, el combate se detiene y aparecen tres Ecos con una explicación corta de su efecto.
7. **Adaptar:** el jugador elige un Eco, modifica su estrategia y continúa a la siguiente sala.

Este loop integra la interfaz con el sistema: no hay una pantalla distinta para aprender a combatir. La lectura de señales, la reacción y la confirmación ocurren en el mismo espacio jugable.

## Dinámicas asociadas y cómo la UI las regula

### Presión y riesgo

La Frecuencia de Nara es la dinámica de riesgo principal. El arco de color permite saber cuándo conviene dejar de atacar, alejarse o jugar con más cuidado. Mostrarla alrededor de la Integridad la relaciona visualmente con el peligro de morir, sin agregar otra barra aislada.

### Dominio del ritmo

El jugador debe aprender el momento del desvío, no reaccionar a un indicador genérico. Por eso la animación y el sonido del enemigo son prioritarios. El destello de confirmación aparece después de la acción, no antes: sirve para aprender con la repetición y no para convertir el combate en un aviso de botón.

### Decisión de construcción

Los Ecos cambian la estrategia de una expedición. Su pantalla aparece únicamente al terminar una sala, cuando no hay peligro. Cada opción incluye un icono, una frase de efecto y una etiqueta corta de estilo, como **Desvío**, **Movilidad** o **Ruptura**. Esto permite comparar sin abrir menús complejos ni romper el ritmo de la partida.

## Principal riesgo del diseño

El mayor riesgo actual es que el jugador no pueda distinguir con claridad la ventana de desvío en salas con varios enemigos, proyectiles y rutas inestables. Si no entiende por qué un desvío funcionó o falló, la dificultad se sentirá injusta. Esto afectaría el sistema de Resonancia completo, porque la Frecuencia y las Rupturas dependen de que el jugador aprenda ese ritmo.

## Validación con un prototipo

Se desarrollaría un prototipo vertical muy corto con una sola sala, dos enemigos y un campo de Frecuencia. Un enemigo usaría ataques lentos y el otro ataques más rápidos, para probar si el feedback mantiene claridad cuando aumenta la presión.

Se invitaría a entre 8 y 12 jugadores con experiencia intermedia en juegos de acción. Durante tres intentos se registrarían estos datos:

- Tiempo hasta realizar el primer desvío preciso.
- Número de daños recibidos por no entender el momento del desvío.
- Veces que la Frecuencia de Nara se llena sin que el jugador note el peligro.
- Capacidad del jugador para explicar, después del intento, por qué falló o acertó.
- Preferencia entre dos versiones del HUD: Frecuencia como arco alrededor de Integridad o como barra independiente.

El prototipo sería viable si la mayoría de los participantes puede realizar un desvío correcto durante los primeros minutos y explicar la causa de sus fallos. Si los jugadores entienden el sistema pero aun así fallan por dificultad, el reto funciona; si no entienden qué ocurrió, se debe ajustar animación, sonido, color o posición de la información antes de crear más contenido.

## Trade-off explícito

El principal trade-off es entre **una interfaz mínima e inmersiva** y **una interfaz más explícita que reduzca la confusión**. Un HUD con indicadores grandes, alertas previas y barras visibles todo el tiempo facilitaría el aprendizaje, pero cubriría animaciones y haría que el combate se sintiera más mecánico. Una interfaz demasiado discreta conservaría la tensión, pero podría frustrar a jugadores intermedios.

La propuesta prioriza un punto medio: los estados permanentes de Nara se muestran en el HUD, mientras que la información de enemigos aparece de forma contextual, cerca del enfrentamiento. Así se mantiene la lectura del espacio y, al mismo tiempo, se entrega el feedback necesario para aprender.

## Justificación de decisiones

Estas decisiones se relacionan directamente con el perfil del juego. *Umbral* está pensado para jugadores intermedios que buscan reto, adaptación y sesiones de 25 a 40 minutos. Necesitan entender rápidamente las reglas básicas, pero también deben sentir que la mejora viene de reconocer patrones y tomar mejores decisiones.

Por eso la interfaz no muestra daño numérico, porcentajes de desvío ni un minimapa completo. En cambio, destaca Integridad, Frecuencia, feedback de precisión y elección de Ecos. La UI no sustituye la habilidad del jugador: regula la información para que una derrota sea legible, una victoria se sienta merecida y el loop roguelite invite a volver a intentar con una estrategia distinta.
