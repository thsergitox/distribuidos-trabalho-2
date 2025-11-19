"""
Implementação do Relógio Lógico de Lamport

O Relógio Lógico de Lamport é um mecanismo para ordenar eventos em sistemas distribuídos
sem necessidade de sincronização de relógios físicos.

Propriedades:
1. Se evento A → B (A causalmente precede a B), então Lamport(A) < Lamport(B)
2. O relógio se incrementa antes de cada evento local
3. Ao receber uma mensagem, o relógio se atualiza: max(local, remote) + 1

Referências:
- Lamport, L. (1978). "Time, Clocks, and the Ordering of Events in a Distributed System"
"""

import threading


class LamportClock:
    """
    Relógio Lógico de Lamport thread-safe

    Attributes:
        time (int): Valor atual do relógio lógico
        lock (threading.Lock): Lock para garantir thread-safety
    """

    def __init__(self, initial_time: int = 0):
        """
        Inicializa o relógio lógico

        Args:
            initial_time: Valor inicial do relógio (por padrão 0)
        """
        self.time = initial_time
        self.lock = threading.Lock()

    def increment(self) -> int:
        """
        Incrementa o relógio local antes de um evento local (ex: enviar mensagem)

        Este método deve ser chamado ANTES de:
        - Enviar uma mensagem a outro nó
        - Realizar qualquer ação que possa causar eventos em outros nós

        Returns:
            int: Novo valor do relógio depois do incremento

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
        Atualiza o relógio ao receber uma mensagem de outro nó

        Implementa a regra de Lamport:
            local_time = max(local_time, remote_time) + 1

        Este método deve ser chamado ao RECEBER uma mensagem que inclui
        o timestamp do nó remoto.

        Args:
            remote_time: Timestamp Lamport da mensagem recebida

        Returns:
            int: Novo valor do relógio local depois da atualização

        Example:
            >>> clock = LamportClock()
            >>> # Recebemos mensagem com timestamp 10
            >>> new_time = clock.update(10)  # Retorna 11
            >>> # Se recebemos outro com timestamp 5
            >>> new_time = clock.update(5)   # Retorna 12 (max(11, 5) + 1)
        """
        with self.lock:
            self.time = max(self.time, remote_time) + 1
            return self.time

    def get_time(self) -> int:
        """
        Obtém o valor atual do relógio sem modificá-lo

        Útil para:
        - Debugging
        - Mostrar em dashboards
        - Logging

        Returns:
            int: Valor atual do relógio

        Example:
            >>> clock = LamportClock()
            >>> clock.increment()
            >>> current = clock.get_time()  # Retorna 1
        """
        with self.lock:
            return self.time

    def __str__(self) -> str:
        """Representação em string do relógio"""
        return f"LamportClock(time={self.get_time()})"

    def __repr__(self) -> str:
        """Representação para debugging"""
        return self.__str__()
