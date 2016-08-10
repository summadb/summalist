import {h} from '@motorcycle/dom'

export function vrendermain (state) {
  return h('div', [
    h('nav'),
    h('main', [
      vrenderitem(state.tree, 'root')
    ]),
    h('footer', 'Scriptable lists.')
  ])
}

function vrenderitem (item, id) {
  return h('div.item', {props: {id}}, [
    h('input.name', {props: {value: item.name._val}}),
    h('input.note', {props: {value: item.note._val}}),
    h('ul.children', item.open._val
      ? Object.keys(item.children || {}).map(id => {
        let child = item.children[id]
        return h('li', {
          props: {className: child.completed._val ? 'completed' : ''}
        }, [vrenderitem(child, id)])
      })
      : []
    )
  ])
}
