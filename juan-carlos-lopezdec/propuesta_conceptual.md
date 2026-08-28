# Actividad 6. Propuesta conceptual de videojuego

**Docente:** MIGUEL ANGEL RODRIGUEZ ORTIZ
**Estudiante:** Juan Carlos Lopez de Cárdenas Avelar
**Fecha:** 28 de agosto de 2026

---

**Título provisional del proyecto:** _Ephemeral Abyss_  
**Género:** Roguelite de acción 2D (Twin-stick shooter / Hack and slash)  
**Estética:** Fantasía oscura (Inspiración visual de calabozos y monstruos estilo _Dungeons & Dragons_)

Para mantener la claridad del diseño, el botín se dividirá en dos categorías:

1.  **Equipamiento Efímero:** Armas, armaduras y objetos consumibles que definen la partida actual y se pierden al morir.
2.  **Vestigios y AURA (Meta-progresión):** El _AURA_ es la moneda permanente, y los _Vestigios_ son las habilidades o boosters pasivos que se guardan para siempre. Estos se equipan automáticamente en la partida si hay espacios (_slots_) vacíos, y pueden gestionarse a voluntad en el nexo principal.

### 1. Mecánica principal (El Verbo)

La acción central es **aniquilar** y **recolectar**. A través de un combate frenético en tiempo real (_hack and slash / twin-stick shooter_), el jugador controla a un avatar neutro que limpia salas cerradas llenas de enemigos. A medida que combate, el personaje muta su estilo de juego adaptándose instintivamente al botín aleatorio (_loot_) que sueltan los enemigos caídos.

### 2. Objetivo del jugador

Sobrevivir el mayor tiempo posible para limpiar la mayor cantidad de salas, romper el récord personal de profundidad o nivel máximo alcanzado, y extraer recursos valiosos para volverse más fuerte en futuras incursiones.

### 3. Reglas básicas

- **Confinamiento arquitectónico:** El avance es estrictamente por salas instanciadas y pre-diseñadas; no es un mundo abierto y no se puede huir del mapa establecido ni avanzar sin despejar la amenaza.
- **Penalización por muerte (Muerte parcial):** Al llegar a cero puntos de salud, el jugador pierde el 100% de su _Equipamiento Efímero_ de esa partida.
- **Conservación de progreso:** El jugador retiene toda el _AURA_ recolectada y los _Vestigios_ obtenidos, asegurando que ninguna partida sea una pérdida total de tiempo.

### 4. Experiencia buscada (Estética)

El jugador debe experimentar una mezcla constante de **adrenalina, anticipación y codicia**.

El combate frenético inyecta la adrenalina, pero es el sistema de recompensas el que ancla la retención. Aprovechando la psicología detrás del _Gacha_ y las _Loot Boxes_, la experiencia se sostiene en el impacto de la aleatoriedad (RNG). Al asignar probabilidades extremadamente bajas a la aparición de _Equipamiento Efímero Legendario_ (armas que cambian por completo el ritmo de la partida haciéndote inmensamente poderoso), se generan picos de dopamina. El jugador siente el impulso adictivo de entrar a "una sala más", motivado por la promesa de que el próximo enemigo podría soltar el objeto definitivo que rompa el balance a su favor.

### 5. Coherencia del diseño (Framework MDA)

Los elementos formales del juego están estrechamente entrelazados para producir un ciclo de juego (_core loop_) adictivo y sin fricciones:

- **Mecánicas (Mechanics):** La arquitectura de generación de niveles selecciona y ensambla salas pre-diseñadas de forma aleatoria. Los algoritmos de caída de botín (RNG) dictan qué tipo de herramientas efímeras (armas) o permanentes (AURA/Vestigios) recibe el jugador neutral tras el combate en tiempo real.
- **Dinámicas (Dynamics):** Como las salas y el equipo cambian en cada partida, el jugador se ve forzado a improvisar diferentes estrategias y "builds" sobre la marcha. La división del inventario crea una economía de riesgo-recompensa: el jugador lamentará perder un arma legendaria al morir (Equipamiento Efímero), pero el dolor se mitiga al ver cómo sus barras de experiencia y _slots_ permanentes se llenan gracias al _AURA_ y los _Vestigios_ recolectados.
- **Estéticas / Experiencia (Aesthetics):** Estas dinámicas erradican la frustración destructiva del "Game Over" tradicional. La pérdida del equipo efímero alimenta el deseo de revancha, mientras que la meta-progresión (AURA) recompensa la constancia. La integración perfecta de la aleatoriedad asegura que la propuesta cumpla su objetivo de ser altamente rejugable y adictiva, empujando siempre al jugador a querer superar su límite anterior.
