In the original code registers are effectively renamed using a level of
indirection and tracking the source of data for any given register. The
register is effectively mapped to a data source. FT64 uses the original
mechanism because it requires fewer resources.

The FT64a version attempts to use register renaming through the register
file. Rather than having a level of indirection the register tags are used
directly to determine the source of data.

