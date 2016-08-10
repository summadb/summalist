import Cycle from '@cycle/most-run'
import {makeDOMDriver} from '@motorcycle/dom'

import {makeTreeDriver} from './tree-driver'
import app from './app'

Cycle.run(app, {
  DOM: makeDOMDriver('#main', {modules: [
    require('snabbdom/modules/props'),
    require('snabbdom/modules/style'),
    require('snabbdom/modules/dataset')
  ]}),
  TREE: makeTreeDriver()
})
