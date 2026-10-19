import { describe, expect, it } from 'vitest'

import { genitiv } from '@/lib/report/elternbericht/genitiv'

describe('genitiv', () => {
  it.each([
    ['Ilkay', 'Ilkays'],
    ['Lena', 'Lenas'],
    ['Max', 'Max’'],
    ['Moritz', 'Moritz’'],
    ['Hans', 'Hans’'],
    ['Felix', 'Felix’'],
    ['Liz', 'Liz’'],
    ['Emil', 'Emils'],
    ['Strauß', 'Strauß’'],
  ])('%s → %s', (name, erwartet) => {
    expect(genitiv(name)).toBe(erwartet)
  })

  it('nimmt den typografischen Apostroph und schneidet Leerraum ab', () => {
    expect(genitiv(' Max ')).toBe('Max’')
  })
})
