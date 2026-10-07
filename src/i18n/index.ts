import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import deCommon from './locales/de/common.json'
import deAdmin from './locales/de/admin.json'
import deAuthoring from './locales/de/authoring.json'
import deScreeningEditor from './locales/de/screening-editor.json'
import deStudent from './locales/de/student.json'
import deMock from './locales/de/mock.json'
import deSlots from './locales/de/slots.json'
import deReport from './locales/de/report.json'
import deParent from './locales/de/parent.json'
import deLeads from './locales/de/leads.json'
import deVertraege from './locales/de/vertraege.json'
import deCoach from './locales/de/coach.json'
import deAkte from './locales/de/akte.json'
import dePruefen from './locales/de/pruefen.json'
import dePruefenAdmin from './locales/de/pruefenAdmin.json'
import deCoachLive from './locales/de/coachLive.json'
import deErklaerPruefen from './locales/de/erklaerPruefen.json'

void i18n.use(initReactI18next).init({
  resources: {
    de: {
      common: deCommon,
      admin: deAdmin,
      authoring: deAuthoring,
      'screening-editor': deScreeningEditor,
      student: deStudent,
      mock: deMock,
      slots: deSlots,
      report: deReport,
      parent: deParent,
      leads: deLeads,
      vertraege: deVertraege,
      coach: deCoach,
      akte: deAkte,
      pruefen: dePruefen,
      pruefenAdmin: dePruefenAdmin,
      coachLive: deCoachLive,
      erklaerPruefen: deErklaerPruefen,
    },
  },
  lng: 'de',
  fallbackLng: 'de',
  defaultNS: 'common',
  ns: [
    'common',
    'admin',
    'authoring',
    'screening-editor',
    'student',
    'mock',
    'report',
    'slots',
    'parent',
    'leads',
    'vertraege',
    'coach',
    'akte',
    'pruefen',
    'pruefenAdmin',
    'coachLive',
    'erklaerPruefen',
  ],
  interpolation: { escapeValue: false },
  returnNull: false,
})

export default i18n
