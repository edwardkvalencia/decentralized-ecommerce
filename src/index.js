import React from 'react'
import ReactDOM from 'react-dom'

class Main extends React.Component {
    constructor() {
        super()
    }

    render() {
        return (
            <div>The project has been setup.</div>
        )
    }
}

ReactDOM.render(<Main />, document.querySelector('#root'))
