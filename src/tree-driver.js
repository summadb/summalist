import most from 'most'

export function makeTreeDriver () {
  return function treeDriver (change$) {
    return most.of({
      name: v('hello'),
      note: v(''),
      completed: v(false),
      open: v(true),
      children: {
        '9347y23h': {
          name: v('world'),
          note: v('~'),
          completed: v(false),
          open: v(true),
          children: {
            '3oi4h32': {
              name: v('what a cliché'),
              note: v(''),
              completed: v(false),
              open: v(true)
            }
          }
        },
        '3oi432o42': {
          name: v('no, not again!'),
          note: v('I\'m done with this.'),
          completed: v(true),
          open: v(true)
        }
      }
    })
  }
}

function v (value) {
  return {_val: value}
}
