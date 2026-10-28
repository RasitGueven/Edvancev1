/**
 * Fassung des Renderers. Sie steckt im Fingerabdruck jedes Renders (SQL: studio_render_fassung()). Ändern sich
 * Bausteine, Skins oder Zeitplan sichtbar, müssen alte Renders als veraltet gelten: dann studio_render_fassung()
 * per Migration erhöhen und hier RENDER_FASSUNG und RENDER_QUELLEN_HASH nachziehen. Kommt nur ein neuer Baustein
 * dazu und bleiben die vorhandenen unverändert, genügt der Hash. fassung.test.ts erinnert daran.
 */
export const RENDER_FASSUNG = 'r1:1920x1080:30:h264-veryfast'
export const RENDER_QUELLEN_HASH = 'dabffaf9ad4efb2165b16e7818cb907db8e817b7baae3965b02180715f0fc898'
