import isolate from '@cycle/isolate'
import most from 'most'
import hold from '@most/hold'
import cuid from 'cuid'
import fwitch from 'fwitch'
import {vrendermain} from './vrender'

export default function main ({DOM, TREE}) {
  let tree$ = TREE

  let state$ = most.of({})

  let vtree$ = most.combine((tree, state) => {
    var renderState = {
      editing: state.editing,
      tree
    }
    return vrendermain(renderState)
  }, tree$, state$)

  return {
    DOM: vtree$
  }
}
