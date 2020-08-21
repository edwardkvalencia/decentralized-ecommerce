import React, { Component } from 'react'
import Header from './Header'

class Sell extends Component {
    constructor() {
        super()

        this.state = {
            title: '',
            description: '',
            price: '',
            image: '',
        }
    }

    async publishProduct() {
        if(this.state.title.length == 0) return alert('You must set the title before publishing product');
        if(this.state.description.length == 0) return alert('You must set the description before publishing the product')
        if(this.state.price.length == 0) return alert('Must set price of product')
        if(this.state.image.length == 0) return alert('You must set the image URL before publishing the product')

        await contract.methods.publishProduct(
            this.state.title,
            this.state.description,
            myWeb3.utils.toWei(this.state.price),
            this.state.image
        ).send()
    }

    render() {
        return (
            <div>
                <Header />
                <div className="sell-page">
                    <h3>Sell Product</h3>
                    <input onChange={event => {
                        this.setState({title: event.target.value})
                    }} type="text" placeholder="Product title..."
                    />

                    <textarea placeholder="Product description" onChange={event => {
                        this.setState({description: event.target.value})
                    }}></textarea>

                    <input onChange={event => {
                        this.setState({price: event.target.value})
                    }} type="text" placeholder="Product price in ETH..."
                    />

                    <input onChange={event => {
                        this.setState({image: event.target.value})
                    }} type="text" placeholder="Product image URL"
                    />

                    <p>Note: shipping costs are priced into final price.</p>

                    <button onClick={() => {
                        this.props.publishProduct(this.state)
                    }} type="button">Publish product</button>
                </div>
            </div>
        )
    }
}

export default Sell