import React, { Component } from 'react'
import MyWeb3 from 'web3'
import Header from './Header'

class Home extends Component {
    constructor() { 
        super() 
    }

    render() {
        return (
            <div>
                <Header />
                <div className="products-container">
                    {this.props.productsHtml}
                </div>
                <div className="spacer"></div>
            </div>
        )
    }

}

export default Home 