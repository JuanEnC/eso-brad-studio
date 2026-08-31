# Umbral: Ciclo de la Ciudad Viva

**Propuesta conceptual de videojuego roguelite**  
**Rogelio Santiago Velasco Pérez**

## Idea general

*Umbral* es un roguelite de acción en tercera persona. El jugador controla a Nara, una exploradora que entra a una ciudad que se reconstruye cada noche. La ciudad guarda recuerdos de sus habitantes como energía llamada **eco**. Cada partida representa una expedición: los distritos, enemigos y mejoras cambian, pero los recuerdos recuperados permiten avanzar la historia desde el refugio central.

## Mecánica principal

La mecánica central es la **Resonancia**. Cada enemigo tiene una barra de **Frecuencia**. Al atacar mantenemos presión, pero el mayor avance ocurre al desviar en el momento exacto. Un desvío correcto produce una señal visual azul y un sonido limpio; además llena la Frecuencia del enemigo. Cuando esta barra se rompe, podemos ejecutar una **Ruptura** para derrotarlo o dejarlo vulnerable. No se trata de golpear sin parar: debemos leer su animación y alternar ataque, defensa y movimiento.

Al terminar una sala de combate, elegimos uno de tres **Ecos**. Estos modifican la partida actual. Por ejemplo, un Eco puede devolver proyectiles después de un desvío perfecto; otro puede hacer que una Ruptura recupere vida; otro puede convertir el dash en una descarga que marca enemigos. Así, el mismo sistema de Resonancia se usa de forma distinta en cada intento.

## Objetivo del jugador

El objetivo de cada partida es atravesar cinco distritos variables, llegar al Núcleo de la ciudad y vencer al Guardián de esa expedición. Durante el recorrido se recuperan **Fragmentos de Memoria**. Al morir o completar la partida, los Fragmentos se conservan en el refugio y desbloquean nuevos Ecos, rutas narrativas y enemigos.

El objetivo a largo plazo es reconstruir la historia de Nara y descubrir por qué la ciudad reinicia su ciclo.

## Reglas básicas

1. Nara tiene tres puntos de integridad. Si los pierde, la expedición termina y comienza una nueva ruta.
2. Atacar no consume estamina; el límite está en exponerse a los ataques enemigos y perder integridad.
3. Un desvío fuera de tiempo protege poco y aumenta la Frecuencia de Nara. Si se llena, queda aturdida por unos segundos.
4. Cada sala completada ofrece un Eco. Se puede elegir solo uno, por lo que una mejora útil obliga a renunciar a otras.
5. La muerte elimina los Ecos obtenidos en esa partida, pero conserva Fragmentos de Memoria y desbloqueos de contenido.
6. No hay mejoras permanentes que aumenten el daño de forma directa.

## Experiencia buscada

Busco que el jugador sienta tensión al entrar a una sala desconocida, pero que esa tensión se convierta en control cuando identifica el ritmo de los ataques. La Resonancia genera esa sensación porque cada acción tiene una respuesta clara: si el desvío fue preciso, el sonido, el efecto visual y la barra de Frecuencia lo confirman. Cuando el jugador falla, puede reconocer qué hizo mal y corregirlo en el siguiente enfrentamiento.

El componente roguelite añade curiosidad y adaptación. La ruta no se memoriza por completo y los Ecos hacen que cada partida tenga una estrategia diferente. Un intento puede favorecer desvíos y contraataques; otro, movilidad y Rupturas. Por eso el jugador no solo mejora su habilidad, también toma decisiones sobre el tipo de combatiente que quiere construir en esa partida.

## Coherencia del diseño: relación MDA

### Mecánicas

- Combate de Resonancia.
- Desvío con tiempo preciso.
- Barra de Frecuencia para enemigos y protagonista.
- Salas y rutas variables.
- Elección de Ecos temporales.
- Desbloqueos narrativos mediante Fragmentos de Memoria.

### Dinámicas

El jugador observa señales, decide si atacar o defender, administra el riesgo de romper su propia Frecuencia y adapta su estrategia según los Ecos recibidos. Cada partida cambia la forma en la que se combinan estas decisiones.

### Estética o experiencia

El juego busca generar reto, concentración, descubrimiento y sensación de dominio. El jugador debe sentir que una derrota se puede entender y que la siguiente partida tiene algo distinto por probar.

## Justificación de la coherencia

Los elementos son coherentes porque todos alimentan el mismo ciclo. El combate preciso entrega Ecos; los Ecos cambian la forma de combatir; las rutas variables obligan a aplicar esa construcción en situaciones nuevas; y los Fragmentos de Memoria dan sentido a volver a intentarlo.

Al evitar mejoras permanentes de daño, el progreso no reemplaza el aprendizaje. La victoria depende de leer mejor, elegir mejor y aprovechar el estilo de partida que se formó durante esa expedición.
