from kivy._event cimport EventDispatcher

cdef class GameManager(EventDispatcher):
    
    def allocate(self, master_buffer, gameworld):
        """
        The GameManager should override and implement this function if it 
        needs to allocate memory. This function will be called by
        GameWorld.allocate.

        Args:
            master_buffer (Buffer): The buffer from which the space for the
            entity IndexedMemoryZone will be allocated.

            gameworld (GameWorld): The GameWorld instance.

        Return: 
            int: The amount of memory allocated by the system.

        """
        return 0

    def deallocate(self, master_buffer, gameworld):
        """
        The GameManager should override and implement this function to 
        free previouslly allocated resources.
        """
        pass
        