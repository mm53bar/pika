// Tom Select's single-file build defines a global rather than exporting; this
// module loads it and exports that global so it can be imported by name.
import "tom-select-complete"
export default globalThis.TomSelect
