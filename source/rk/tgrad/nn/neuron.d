module rk.tgrad.nn.neuron;

import rk.tgrad.core.common;
import rk.tgrad.core.value;
import rk.tgrad.aux.activation;

class Neuron : INeuron
{
    Value[] params;
    Value function(Value) activate;

    this(in size_t inputSize, Value function(Value) activate = &activateLinear) {
        foreach (i; 0..inputSize+1) this.params ~= value();
        this.activate = activate;
    }

    Value forward(Value[] input) in (input.length+1 == parameters.length)
    {
        auto sum = value(0);
        foreach (i, x; input) sum = sum + params[i]*x;
        return activate(sum + params[$-1]);
    }

    Value[] parameters()
    {
        Value[] paramsList;
        foreach (p; this.params) paramsList ~= p.parameters;
        return paramsList;
    }

    ElementType[] parameterValues()
    {
        ElementType[] paramsList;
        foreach (p; this.params) paramsList ~= p.parameterValues;
        return paramsList;
    }

    ElementType[] parameterGrads()
    {
        ElementType[] paramsList;
        foreach (p; this.params) paramsList ~= p.parameterGrads;
        return paramsList;
    }
}

unittest
{
    import std.stdio;

    // define model
    auto neuron = new Neuron(2);

    // define data
    auto input = [
        [value(0), value(0)],
        [value(1), value(0)],
        [value(0), value(1)],
        [value(1), value(1)],
    ];
    auto target = [
        0.value, 1.value, 1.value, 1.value
    ];

    // train
    enum lr = 0.05;
    enum epochs = 100;
    foreach (epoch; 0..epochs)
    {
        auto loss = value(0);
        float accuracy = 0;
        foreach (i, x; input)
        {
            // forward
            auto yhat = neuron.forward(x);

            // loss and accuracy
            loss = loss + (yhat - target[i]) * (yhat - target[i]);
            accuracy += (yhat.data > 0.5) == target[i].data;
        }
        loss = loss / input.length;
        accuracy /= input.length;
        
        // backward
        neuron.zeroGrad();
        loss.backward();

        // update
        neuron.update(lr);

        // if (epoch % 10 == 0) writefln("epoch %3s loss %.4f accuracy %.4f", epoch, loss.data, accuracy);
    }

    // predict
    auto pred = neuron.forward([1.value, 1.value]);
    assert(pred.data > 0.5);

    // test parameters property
    neuron.parameters[0].grad = 2;
    assert(neuron.params[0].grad == 2);
}

