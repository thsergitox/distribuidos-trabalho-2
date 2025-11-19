"""
Implementación del Reloj Lógico de Lamport

El Reloj Lógico de Lamport es un mecanismo para ordenar eventos en sistemas distribuidos
sin necesidad de sincronización de relojes físicos.

Propiedades:
1. Si evento A → B (A causalmente precede a B), entonces Lamport(A) < Lamport(B)
2. El reloj se incrementa antes de cada evento local
3. Al recibir un mensaje, el reloj se actualiza: max(local, remote) + 1

Referencias:
- Lamport, L. (1978). "Time, Clocks, and the Ordering of Events in a Distributed System"
"""

import threading


class LamportClock:
    """
    Reloj Lógico de Lamport thread-safe

    Attributes:
        time (int): Valor actual del reloj lógico
        lock (threading.Lock): Lock para garantizar thread-safety
    """

    def __init__(self, initial_time: int = 0):
        """
        Inicializa el reloj lógico

        Args:
            initial_time: Valor inicial del reloj (por defecto 0)
        """
        self.time = initial_time
        self.lock = threading.Lock()

    def increment(self) -> int:
        """
        Incrementa el reloj local antes de un evento local (ej: enviar mensaje)

        Este método debe llamarse ANTES de:
        - Enviar un mensaje a otro nodo
        - Realizar cualquier acción que pueda causar eventos en otros nodos

        Returns:
            int: Nuevo valor del reloj después del incremento

        Example:
            >>> clock = LamportClock()
            >>> timestamp = clock.increment()  # Retorna 1
            >>> send_message(data, timestamp=timestamp)
        """
        with self.lock:
            self.time += 1
            return self.time

    def update(self, remote_time: int) -> int:
        """
        Actualiza el reloj al recibir un mensaje de otro nodo

        Implementa la regla de Lamport:
            local_time = max(local_time, remote_time) + 1

        Este método debe llamarse al RECIBIR un mensaje que incluye
        el timestamp del nodo remoto.

        Args:
            remote_time: Timestamp Lamport del mensaje recibido

        Returns:
            int: Nuevo valor del reloj local después de la actualización

        Example:
            >>> clock = LamportClock()
            >>> # Recibimos mensaje con timestamp 10
            >>> new_time = clock.update(10)  # Retorna 11
            >>> # Si recibimos otro con timestamp 5
            >>> new_time = clock.update(5)   # Retorna 12 (max(11, 5) + 1)
        """
        with self.lock:
            self.time = max(self.time, remote_time) + 1
            return self.time

    def get_time(self) -> int:
        """
        Obtiene el valor actual del reloj sin modificarlo

        Útil para:
        - Debugging
        - Mostrar en dashboards
        - Logging

        Returns:
            int: Valor actual del reloj

        Example:
            >>> clock = LamportClock()
            >>> clock.increment()
            >>> current = clock.get_time()  # Retorna 1
        """
        with self.lock:
            return self.time

    def __str__(self) -> str:
        """Representación en string del reloj"""
        return f"LamportClock(time={self.get_time()})"

    def __repr__(self) -> str:
        """Representación para debugging"""
        return self.__str__()
